# Konfiguracja providera AWS
provider "aws" {
    region = "eu-north-1"  # Region AWS, w którym będą tworzone zasoby
}

# Konfiguracja szablonu instancji EC2 dla Auto Scaling Group
resource "aws_launch_template" "example" {
    image_id = "ami-0a664360bb4a53714"  # ID obrazu AMI (Amazon Machine Image) - system operacyjny
    instance_type = "t3.micro"  # Typ instancji - rozmiar zasobów (CPU, RAM)
    
    # Lista ID grup bezpieczeństwa przypisanych do instancji w VPC
    vpc_security_group_ids = [aws_security_group.instance.id]

    # Skrypt uruchamiany przy starcie instancji - base64encode koduje skrypt do formatu wymaganego przez AWS
    # Skrypt: sprawdza czy Python3 jest zainstalowany, instaluje go jeśli potrzeba, tworzy index.html i uruchamia serwer HTTP
    user_data = base64encode(<<EOF
              #!/bin/bash
              command -v python3 >/dev/null 2>&1 || (yum install -y python3 || dnf install -y python3 || (apt-get update && apt-get install -y python3))
              echo "Hello world" > index.html
              nohup python3 -m http.server ${var.server_port} &
              EOF
              )
  
    
    # Lifecycle hook - tworzy nową instancję przed zniszczeniem starej (zero-downtime deployment)
    lifecycle { 
        create_before_destroy = true
    }
    
}

resource "aws_security_group" "instance" {
    name = var.instance_security_group_name

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Auto Scaling Group - automatycznie skaluje liczbę instancji w zależności od obciążenia
resource "aws_autoscaling_group" "example" {    
    vpc_zone_identifier = data.aws_subnets.default.ids  # Subnety, w których będą tworzone instancje

    target_group_arns = [aws_lb_target_group.asg.arn]  # Grupa docelowa Load Balancera
    health_check_type = "ELB"  # Typ health check - ELB sprawdza zdrowie instancji przez Load Balancer
    

    min_size = 2  # Minimalna liczba działających instancji
    max_size = 10  # Maksymalna liczba instancji (Auto Scaling może zwiększyć do tej wartości)

    launch_template {
        id = aws_launch_template.example.id
        version = "$Latest"
    }

    # Tagi przypisywane do każdej instancji w grupie
    tag {
        key = "Name"
        value = var.alb_name  # Nazwa instancji
        propagate_at_launch = true  # Tag jest propagowany do wszystkich nowych instancji
    }
}

# Pobranie informacji o domyślnej VPC (Virtual Private Cloud)
data "aws_vpc" "default" {
    default = true  # Wybiera domyślną VPC w regionie
}

# Pobranie listy subnetów należących do domyślnej VPC
data "aws_subnets" "default" {
    filter {
        name = "vpc-id"  # Filtr po ID VPC
        values = [data.aws_vpc.default.id]  # Wartość - ID domyślnej VPC
    }
}

# Application Load Balancer - rozdziela ruch HTTP/HTTPS między instancje
resource "aws_lb" "example" {
    name = var.alb_name  # Nazwa Load Balancera
    load_balancer_type = "application"  # Typ ALB - działa na warstwie 7 (HTTP/HTTPS)
    subnets = data.aws_subnets.default.ids  # Subnety, w których będzie działał ALB (minimum 2 w różnych strefach dostępności)
    security_groups = [aws_security_group.alb.id]  # Grupa bezpieczeństwa dla ALB
}

# Listener Load Balancera - nasłuchuje na określonym porcie i protokole
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn  # ARN Load Balancera, do którego jest przypisany listener
    port  = 80  # Port HTTP
    protocol = "HTTP"  # Protokół HTTP

    # Domyślna akcja, gdy żadna reguła nie pasuje do żądania
    default_action {
        type = "fixed-response"  # Zwraca stałą odpowiedź

        fixed_response {
            content_type = "text/plain"  # Typ zawartości odpowiedzi
            message_body = "404: Nie znaleziono strony"  # Treść odpowiedzi
            status_code = 404  # Kod statusu HTTP
        }
    }
}

# Grupa bezpieczeństwa dla Application Load Balancera - reguły firewall
resource "aws_security_group" "alb" {
    name = var.alb_security_group_name  # Nazwa grupy bezpieczeństwa

    # Reguły przychodzące (ingress) - kto może łączyć się z ALB
    ingress {
        from_port = 80  # Port początkowy
        to_port = 80  # Port końcowy
        protocol = "tcp"  # Protokół TCP
        cidr_blocks = ["0.0.0.0/0"]  # Zezwól na ruch z dowolnego adresu IP (Internet)
    }

    # Reguły wychodzące (egress) - dokąd ALB może wysyłać ruch
    egress {
        from_port = 0  # Port początkowy (0 = wszystkie)
        to_port = 0  # Port końcowy (0 = wszystkie)
        protocol = "-1"  # -1 = wszystkie protokoły
        cidr_blocks = ["0.0.0.0/0"]  # Do dowolnego adresu IP
    }
}

# Target Group - grupa docelowa instancji, do których ALB kieruje ruch
resource "aws_lb_target_group" "asg" {
    name = var.alb_name  # Nazwa grupy docelowej
    port = var.server_port  # Port, na którym nasłuchują instancje
    protocol = "HTTP"  # Protokół komunikacji z instancjami
    vpc_id = data.aws_vpc.default.id  # VPC, w której znajdują się instancje

    # Health check - sprawdzanie, czy instancje są zdrowe i gotowe do przyjmowania ruchu
    health_check {
        path = "/"  # Ścieżka HTTP używana do sprawdzania zdrowia
        protocol = "HTTP"  # Protokół health check
        matcher = "200"  # Kod statusu HTTP oznaczający zdrową instancję
        interval = 15  # Częstotliwość sprawdzania (w sekundach)
        timeout = 3  # Timeout pojedynczego sprawdzenia (w sekundach)
        healthy_threshold = 2  # Liczba kolejnych udanych sprawdzeń, aby uznać instancję za zdrową
        unhealthy_threshold = 2  # Liczba kolejnych nieudanych sprawdzeń, aby uznać instancję za niezdrową
    }
}

# Reguła listenera - określa, kiedy i dokąd przekierować ruch
resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn  # Listener, do którego jest przypisana reguła
    priority = 100  # Priorytet reguły (niższa liczba = wyższy priorytet)

    # Warunek, kiedy reguła ma być zastosowana
    condition {
        path_pattern {
            values =["*"]  # Wzorzec ścieżki - "*" oznacza wszystkie ścieżki
        }
    }

    # Akcja wykonywana, gdy warunek jest spełniony
    action {
        type = "forward"  # Przekieruj ruch do Target Group
        target_group_arn = aws_lb_target_group.asg.arn  # ARN grupy docelowej
    }
}
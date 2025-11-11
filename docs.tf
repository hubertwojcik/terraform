variable "number_example" {
    description = "Number of example"
    type = number
    default = 42
}

variable "list_example" {
    description = "List of example"
    type = list
    default = ["a", "b", "c"]
}

variable "map_example" {
    description = "Map of example"
    type = map(string)
    default = {
        key1 = "value1"
        key2 = "value2"
        key3 = "value3"
    }
}

variable "object_example" {
    description = "Object of example"
    type = object({
        key1 = string
        key2 = number
        key3 = list(string)
        key4 = map(string)
        key5 = bool
    })
    default = {
        key1 = "value1"
        key2 = 42
        key3 = ["a", "b", "c"]
        key4 = { key1 = "value1", key2 = "value2", key3 = "value3" }
        key5 = true
    }
}
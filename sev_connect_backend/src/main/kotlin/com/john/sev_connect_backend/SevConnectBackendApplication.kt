package com.john.sev_connect_backend

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.context.properties.ConfigurationPropertiesScan
import org.springframework.boot.runApplication

@SpringBootApplication
@ConfigurationPropertiesScan
class SevConnectBackendApplication

fun main(args: Array<String>) {
    runApplication<SevConnectBackendApplication>(*args)
}

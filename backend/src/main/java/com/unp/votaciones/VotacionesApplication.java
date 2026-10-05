package com.unp.votaciones;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class VotacionesApplication {

    public static void main(String[] args) {
        SpringApplication.run(VotacionesApplication.class, args);
        System.out.println("✅ Sistema de Elecciones UNP Backend Iniciado.");
    }

}

package com.example.productservice;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.PublishRequest;
import software.amazon.awssdk.services.sns.model.PublishResponse;

@Service
public class SnsService {

    private final SnsClient snsClient;
    private final ObjectMapper objectMapper;

    @Value("${sns.topic.name}")
    private String topicArn;

    public SnsService() {
        this.snsClient = SnsClient.create();
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
    }

    public void publishProductEvent(Product product) {
        try {
            String message = objectMapper.writeValueAsString(product);
            PublishRequest request = PublishRequest.builder()
                    .topicArn(topicArn)
                    .message(message)
                    .build();
            PublishResponse response = snsClient.publish(request);
            System.out.println("Published product event: " + response.messageId());
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }
    }
}

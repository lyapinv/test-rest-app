package ru.vtb.istio.app.srv_a.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

@RestController
public class ClientController {

    @Autowired
    private RestTemplate restTemplate;

    @Value("${SERVICE_B_URI}")
    private String remoteURL;

    private final Logger logger = LoggerFactory.getLogger(getClass());

    @RequestMapping("/ping")
    public String ping() {
        System.out.println("!!! Call A service ping method. Reply PONG");
        return "pong";
    }

    @RequestMapping("/citiesCount")
    public Integer citiesCount() {
        try {
            ResponseEntity<String> responseEntity = restTemplate.getForEntity(remoteURL + "/cities", String.class);
            String response = responseEntity.getBody();
            System.out.println("!!! response: " + response);
        } catch (HttpStatusCodeException ex) {
            logger.warn("Exception trying to get the response from recommendation service.", ex);
        } catch (RestClientException ex) {
            logger.warn("Exception trying to get the response from recommendation service.", ex);
        }
        return 3;
    }

//    @RequestMapping("/maxPopulationCity")
//    public String findCityWithMaxPopulation() {
//
//        return cityService.findById(cityId);
//    }

    @ExceptionHandler(value = {Exception.class})
    public ResponseEntity<Object> handleException(Exception e) {

        System.out.println("!!! Error on A service. Return http 503 error code: " + e.getMessage());
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(e.getMessage());
    }
}
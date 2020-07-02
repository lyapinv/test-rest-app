package ru.vtb.istio.app.srv_b.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.vtb.istio.app.srv_b.model.City;
import ru.vtb.istio.app.srv_b.service.ICityService;

import java.util.List;

@RestController
public class CityController {

    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Autowired
    private JdbcTemplate jtm;

    @Autowired
    private ICityService cityService;

    @RequestMapping("/ping")
    public String ping() {
        System.out.println("!!! New Call B service ping method. Reply PONG");
        System.out.println("jtm: " + jtm);
        logger.info(" $$$ ping/pong");
        return "pong";
    }

    @RequestMapping("/cities")
    public List<City> findCities() {

        return cityService.findAll();
    }

    @RequestMapping("/cities/{cityId}")
    public City findCity(@PathVariable Long cityId) {

        return cityService.findById(cityId);
    }

    @ExceptionHandler(value = {Exception.class})
    public ResponseEntity<Object> handleException(Exception e) {

        System.out.println("!!! Error on noCityFound(). Return http 503 error code: " + e.getMessage());
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(e.getMessage());
    }
}
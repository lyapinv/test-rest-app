package ru.vtb.istio.app.srv_b.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.vtb.istio.app.srv_b.service.ICityService;

@RestController
public class ExtController {

    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Autowired
    private ICityService cityService;

    @RequestMapping("/ext/ping")
    public String ping() {
        System.out.println("!!! Call Ext service ping method. Reply PONG");
        logger.info(" $$$ ping/pong");
        return "pong";
    }
}
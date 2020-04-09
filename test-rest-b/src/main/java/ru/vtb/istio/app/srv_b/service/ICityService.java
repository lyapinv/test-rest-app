package ru.vtb.istio.app.srv_b.service;

import ru.vtb.istio.app.srv_b.model.City;

import java.util.List;

public interface ICityService {

    List<City> findAll();

    City findById(Long id);
}

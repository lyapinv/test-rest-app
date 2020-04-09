package ru.vtb.istio.app.srv_b.service;

import org.springframework.stereotype.Service;
import ru.vtb.istio.app.srv_b.model.City;

import java.util.Arrays;
import java.util.List;

@Service
public class CityService implements ICityService {

    private final List<City> cities = Arrays.asList(
            new City(1L, "Bratislava", 432000),
            new City(2L, "Budapest", 1759000),
            new City(3L, "Berlin", 3671000)
    );

    @Override
    public List<City> findAll() {
        return cities;
    }

    @Override
    public City findById(Long id) {
        return cities.stream()
                .filter(c -> c.getId() == 1)
                .findFirst().get();
    }
}
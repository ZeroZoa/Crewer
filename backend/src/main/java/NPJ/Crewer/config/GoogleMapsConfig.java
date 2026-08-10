package NPJ.Crewer.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/config")
public class GoogleMapsConfig {

    @Value("${google.maps.api.key}")  // application.properties에서 불러오기
    private String apiKey;

    @Value("${google.maps.map.id}")  // application.properties에서 불러오기
    private String mapId;

    @GetMapping("/google-maps-key")
    public String getGoogleMapsApiKey() {
        return apiKey;
    }

    @GetMapping("/google-maps-map-id")
    public String getGoogleMapsMapId() {
        return mapId;
    }
}
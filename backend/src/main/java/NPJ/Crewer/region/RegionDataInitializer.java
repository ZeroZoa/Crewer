package NPJ.Crewer.region;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.io.InputStream;
import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class RegionDataInitializer implements ApplicationRunner {

    private final ProvinceRepository provinceRepository;
    private final CityRepository cityRepository;
    private final DistrictRepository districtRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private static final Logger logger = LoggerFactory.getLogger(RegionDataInitializer.class);

    @Override
    @Transactional
    public void run(ApplicationArguments args) throws Exception {
        // DB에 데이터가 이미 있으면 실행하지 않음
        if (provinceRepository.count() > 0) {
            logger.info("Region data already initialized. Skipping initialization.");
            return;
        }

        logger.info("Starting region data initialization from GeoJSON files...");

        // 1. 시/도 데이터 초기화
        initializeProvinces();
        
        // 2. 시/군/구 데이터 초기화
        initializeCities();
        
        // 3. 행정동 데이터 초기화
        initializeDistricts();

        logger.info("Region data initialization completed successfully!");
        logger.info("Provinces: {}, Cities: {}, Districts: {}", 
                   provinceRepository.count(), 
                   cityRepository.count(), 
                   districtRepository.count());
    }

    private void initializeProvinces() throws Exception {
        logger.info("Initializing provinces...");
        
        // 시/도 기본 데이터 (GeoJSON 파일명에서 추출)
        Map<String, ProvinceData> provinceDataMap = new HashMap<>();
        provinceDataMap.put("11", new ProvinceData("11", "서울특별시", "hangjeongdong_서울특별시_30%.json", 37.5665, 126.9780));
        provinceDataMap.put("26", new ProvinceData("26", "부산광역시", "hangjeongdong_부산광역시_30%.json", 35.1796, 129.0756));
        provinceDataMap.put("27", new ProvinceData("27", "대구광역시", "hangjeongdong_대구광역시_30%.json", 35.8714, 128.6014));
        provinceDataMap.put("28", new ProvinceData("28", "인천광역시", "hangjeongdong_인천광역시_30%.json", 37.4563, 126.7052));
        provinceDataMap.put("29", new ProvinceData("29", "광주광역시", "hangjeongdong_광주광역시_30%.json", 35.1595, 126.8526));
        provinceDataMap.put("30", new ProvinceData("30", "대전광역시", "hangjeongdong_대전광역시_30%.json", 36.3504, 127.3845));
        provinceDataMap.put("31", new ProvinceData("31", "울산광역시", "hangjeongdong_울산광역시_30%.json", 35.5384, 129.3114));
        provinceDataMap.put("36", new ProvinceData("36", "세종특별자치시", "hangjeongdong_세종특별자치시_30%.json", 36.4870, 127.2820));
        provinceDataMap.put("41", new ProvinceData("41", "경기도", "hangjeongdong_경기도_15%.json", 37.4138, 127.5183));
        provinceDataMap.put("42", new ProvinceData("42", "강원도", "hangjeongdong_강원도_30%.json", 37.8228, 128.1555));
        provinceDataMap.put("43", new ProvinceData("43", "충청북도", "hangjeongdong_충청북도_30%.json", 36.8, 127.7));
        provinceDataMap.put("44", new ProvinceData("44", "충청남도", "hangjeongdong_충청남도_30%.json", 36.5184, 126.8000));
        provinceDataMap.put("45", new ProvinceData("45", "전라북도", "hangjeongdong_전라북도_30%.json", 35.7175, 127.1530));
        provinceDataMap.put("46", new ProvinceData("46", "전라남도", "hangjeongdong_전라남도_15%.json", 34.8679, 126.9910));
        provinceDataMap.put("47", new ProvinceData("47", "경상북도", "hangjeongdong_경상북도_15%.json", 36.4919, 128.8889));
        provinceDataMap.put("48", new ProvinceData("48", "경상남도", "hangjeongdong_경상남도_15%.json", 35.4606, 128.2132));
        provinceDataMap.put("50", new ProvinceData("50", "제주특별자치도", "hangjeongdong_제주특별자치도_30%.json", 33.4996, 126.5312));

        List<Province> provinces = new ArrayList<>();
        for (ProvinceData data : provinceDataMap.values()) {
            Province province = new Province(
                data.regionId, 
                data.regionName, 
                "시/도", 
                data.latitude, 
                data.longitude, 
                data.geojsonFilePath
            );
            provinces.add(province);
        }
        
        provinceRepository.saveAll(provinces);
        logger.info("Initialized {} provinces", provinces.size());
    }

    private void initializeCities() throws Exception {
        logger.info("Initializing cities from GeoJSON files...");
        
        // 1. DB에 저장된 모든 Province 목록을 가져옴 (한 번만 조회)
        List<Province> allProvinces = provinceRepository.findAll();
        Map<String, Province> provincesMap = allProvinces.stream()
                .collect(Collectors.toMap(Province::getRegionId, province -> province));
        
        List<City> allCitiesToSave = new ArrayList<>();
        
        // 3. 각 Province를 순회하며 해당하는 GeoJSON 파일에서 시/군/구 데이터 추출
        for (Province province : allProvinces) {
            String fileName = province.getGeojsonFilePath();
            if (fileName == null || fileName.isBlank()) {
                logger.warn("GeoJSON file path is missing for province: {}", province.getRegionName());
                continue;
            }
            
            logger.info("Processing cities from file: {}", fileName);
            Set<String> processedSggCodes = new HashSet<>(); // 중복 방지
            
            try {
                ClassPathResource resource = new ClassPathResource("static/geojson/" + fileName);
                InputStream inputStream = resource.getInputStream();
                
                JsonNode geoJsonData = objectMapper.readTree(inputStream);
                JsonNode features = geoJsonData.get("features");
                
                for (JsonNode feature : features) {
                    JsonNode properties = feature.get("properties");
                    String sggCode = properties.get("sgg").asText();
                    
                    // 이미 처리한 시/군/구는 건너뛰기
                    if (processedSggCodes.contains(sggCode)) {
                        continue;
                    }
                    
                    String sggName = properties.get("sggnm").asText();
                    String fullName = province.getRegionName() + " " + sggName;
                    
                    // 시/군/구의 중심 좌표 계산 (해당 시/군/구의 모든 행정동 좌표 평균)
                    JsonNode geometry = feature.get("geometry");
                    JsonNode coordinates = geometry.get("coordinates").get(0);
                    BigDecimal centerLat = BigDecimal.ZERO;
                    BigDecimal centerLng = BigDecimal.ZERO;
                    int coordCount = 0;
                    
                    for (JsonNode coord : coordinates) {
                        centerLng = centerLng.add(BigDecimal.valueOf(coord.get(0).asDouble()));
                        centerLat = centerLat.add(BigDecimal.valueOf(coord.get(1).asDouble()));
                        coordCount++;
                    }
                    
                    if (coordCount > 0) {
                        centerLat = centerLat.divide(BigDecimal.valueOf(coordCount), 6, java.math.RoundingMode.HALF_UP);
                        centerLng = centerLng.divide(BigDecimal.valueOf(coordCount), 6, java.math.RoundingMode.HALF_UP);
                    }
                    
                                         City city = new City(
                         sggCode,
                         sggName,
                         fullName,
                         "시/군/구",
                         province,
                         centerLat,
                         centerLng
                     );
                    
                    allCitiesToSave.add(city);
                    processedSggCodes.add(sggCode);
                }
                
                logger.info("Found {} cities in {}", processedSggCodes.size(), fileName);
                
            } catch (Exception e) {
                logger.error("Error processing cities from file: " + fileName, e);
            }
        }
        
        // 4. 모든 시/군/구 데이터를 DB에 일괄 저장
        cityRepository.saveAll(allCitiesToSave);
        logger.info("Total initialized cities: {}", allCitiesToSave.size());
    }

    private void initializeDistricts() throws Exception {
        logger.info("Initializing all districts from GeoJSON files...");
        
        // 1. 모든 City 데이터를 미리 Map에 저장 (성능 최적화 - N+1 문제 해결)
        Map<String, City> citiesMap = cityRepository.findAll().stream()
                .collect(Collectors.toMap(City::getRegionId, city -> city));
        
        // 2. DB에 저장된 모든 Province 목록을 가져옴
        List<Province> allProvinces = provinceRepository.findAll();
        List<District> allDistrictsToSave = new ArrayList<>();
        
        // 3. 각 Province를 순회하며 해당하는 GeoJSON 파일 처리
        for (Province province : allProvinces) {
            String fileName = province.getGeojsonFilePath();
            if (fileName == null || fileName.isBlank()) {
                logger.warn("GeoJSON file path is missing for province: {}", province.getRegionName());
                continue;
            }
            
            logger.info("Processing districts from file: {}", fileName);
            List<District> districtsFromFile = new ArrayList<>();
            
            try {
                ClassPathResource resource = new ClassPathResource("static/geojson/" + fileName);
                InputStream inputStream = resource.getInputStream();
                
                JsonNode geoJsonData = objectMapper.readTree(inputStream);
                JsonNode features = geoJsonData.get("features");
                
                for (JsonNode feature : features) {
                    JsonNode properties = feature.get("properties");
                    JsonNode geometry = feature.get("geometry");
                    
                    String sggCode = properties.get("sgg").asText();
                    City city = citiesMap.get(sggCode);
                    
                    if (city == null) {
                        logger.warn("City not found in map for sgg code: {} in file {}", sggCode, fileName);
                        continue; // city가 없으면 이 district는 건너뛰기
                    }
                    
                    String admCd = properties.get("adm_cd").asText();
                    String admNm = properties.get("adm_nm").asText();
                    
                    // 좌표 계산 (폴리곤의 중심점)
                    JsonNode coordinates = geometry.get("coordinates").get(0);
                    BigDecimal centerLat = BigDecimal.ZERO;
                    BigDecimal centerLng = BigDecimal.ZERO;
                    int coordCount = 0;
                    
                    for (JsonNode coord : coordinates) {
                        centerLng = centerLng.add(BigDecimal.valueOf(coord.get(0).asDouble()));
                        centerLat = centerLat.add(BigDecimal.valueOf(coord.get(1).asDouble()));
                        coordCount++;
                    }
                    
                    if (coordCount > 0) {
                        centerLat = centerLat.divide(BigDecimal.valueOf(coordCount), 6, java.math.RoundingMode.HALF_UP);
                        centerLng = centerLng.divide(BigDecimal.valueOf(coordCount), 6, java.math.RoundingMode.HALF_UP);
                    }
                    
                    // 행정동명 추출 (전체 주소에서 마지막 부분)
                    String[] parts = admNm.split(" ");
                    String districtName = parts[parts.length - 1];
                    
                                         District district = new District(
                         admCd,
                         districtName,
                         admNm,
                         "동/읍/면",
                         city,
                         centerLat,
                         centerLng,
                         geometry.toString() // GeoJSON 데이터 저장
                     );
                    
                    districtsFromFile.add(district);
                }
                
                allDistrictsToSave.addAll(districtsFromFile);
                logger.info("Found {} districts in {}", districtsFromFile.size(), fileName);
                
            } catch (Exception e) {
                logger.error("Error processing file: " + fileName, e);
            }
        }
        
        // 4. 모든 행정동 데이터를 DB에 일괄 저장
        districtRepository.saveAll(allDistrictsToSave);
        logger.info("Total initialized districts: {}", allDistrictsToSave.size());
    }

    // 내부 데이터 클래스들
    private static class ProvinceData {
        String regionId, regionName, geojsonFilePath;
        Double latitude, longitude;
        
        ProvinceData(String regionId, String regionName, String geojsonFilePath, Double latitude, Double longitude) {
            this.regionId = regionId;
            this.regionName = regionName;
            this.geojsonFilePath = geojsonFilePath;
            this.latitude = latitude;
            this.longitude = longitude;
        }
    }
    

}

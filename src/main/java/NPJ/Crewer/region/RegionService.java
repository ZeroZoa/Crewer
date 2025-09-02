package NPJ.Crewer.region;

import NPJ.Crewer.member.Member;
import NPJ.Crewer.region.dto.ActivityRegionRequestDTO;
import NPJ.Crewer.region.dto.CityResponseDTO;
import NPJ.Crewer.region.dto.DistrictResponseDTO;
import NPJ.Crewer.region.dto.ProvinceResponseDTO;
import NPJ.Crewer.region.RegionNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RegionService {

    private final ProvinceRepository provinceRepository;
    private final CityRepository cityRepository;
    private final DistrictRepository districtRepository;
    private final MemberActivityRegionRepository memberActivityRegionRepository;

    // 모든 시/도 목록 조회
    public List<ProvinceResponseDTO> getAllProvinces() {
        return provinceRepository.findAllByOrderByRegionNameAsc()
                .stream()
                .map(ProvinceResponseDTO::from)
                .collect(Collectors.toList());
    }

    // 특정 시/군/구 내에서 행정동 검색 (모든 데이터 반환)
    public List<DistrictResponseDTO> searchDistrictsInCity(String cityId, String query, int limit) {
        List<District> districts;
        
        if (query == null || query.trim().isEmpty()) {
            // 검색어가 없으면 모든 행정동 반환
            districts = districtRepository.findByCityRegionIdOrderByRegionNameAsc(cityId);
        } else {
            // 검색어가 있으면 검색 결과 반환 (Pageable 제거)
            districts = districtRepository.findByCityIdAndRegionNameContaining(cityId, query.trim());
        }
        
        // limit이 설정되어 있으면 클라이언트에서 제한
        if (limit > 0 && districts.size() > limit) {
            districts = districts.subList(0, limit);
        }
        
        return districts.stream()
                .map(DistrictResponseDTO::from)
                .collect(Collectors.toList());
    }

    // 특정 시/도 내의 모든 시/군/구 조회 (Fetch Join으로 N+1 문제 해결)
    public List<CityResponseDTO> getCitiesInProvince(String provinceId) {
        List<City> cities = cityRepository.findByProvinceRegionIdWithProvince(provinceId);
        return cities.stream()
                .map(CityResponseDTO::from)
                .collect(Collectors.toList());
    }

    // 특정 시/도 내의 모든 행정동 조회
    public List<DistrictResponseDTO> getAllDistrictsInProvince(String provinceId) {
        List<District> districts = districtRepository.findByCityProvinceRegionIdOrderByRegionNameAsc(provinceId);
        return districts.stream()
                .map(DistrictResponseDTO::from)
                .collect(Collectors.toList());
    }

    // 특정 시/도 내에서 행정동 검색 (자동완성용)
    public List<DistrictResponseDTO> searchDistrictsInProvince(String provinceId, String query) {
        List<District> districts = districtRepository.findByProvinceIdAndRegionNameContaining(provinceId, query);
        return districts.stream()
                .map(DistrictResponseDTO::from)
                .collect(Collectors.toList());
    }

    // 행정동 상세 정보 조회
    public DistrictResponseDTO getDistrictDetail(String districtId) {
        District district = districtRepository.findByRegionId(districtId)
                .orElseThrow(() -> new RegionNotFoundException("존재하지 않는 행정동입니다."));
        return DistrictResponseDTO.from(district);
    }

    // 사용자 활동 지역 설정
    @Transactional
    public DistrictResponseDTO setActivityRegion(Member member, ActivityRegionRequestDTO request) {
        // 행정동 존재 여부 확인
        District district = districtRepository.findByRegionId(request.getRegionId())
                .orElseThrow(() -> new RegionNotFoundException("존재하지 않는 행정동입니다."));

        // 기존 활동 지역이 있는지 확인
        MemberActivityRegion existingActivityRegion = memberActivityRegionRepository.findByMember(member)
                .orElse(null);

        if (existingActivityRegion != null) {
            // 기존 활동 지역 업데이트
            existingActivityRegion.updateDistrict(district);
            memberActivityRegionRepository.save(existingActivityRegion);
        } else {
            // 새로운 활동 지역 생성
            MemberActivityRegion newActivityRegion = new MemberActivityRegion(member, district);
            memberActivityRegionRepository.save(newActivityRegion);
        }

        return DistrictResponseDTO.from(district);
    }

    // 사용자 활동 지역 조회
    public DistrictResponseDTO getActivityRegion(Member member) {
        MemberActivityRegion activityRegion = memberActivityRegionRepository.findByMember(member)
                .orElse(null);

        if (activityRegion == null) {
            return null;
        }

        return DistrictResponseDTO.from(activityRegion.getDistrict());
    }

    // 특정 시/도의 GeoJSON 파일 읽기
    public String getProvinceGeoJson(String provinceId) {
        Province province = provinceRepository.findById(provinceId)
                .orElseThrow(() -> new RegionNotFoundException("존재하지 않는 시/도입니다."));
        
        try {
            Resource resource = new ClassPathResource("static/geojson/" + province.getGeojsonFilePath());
            return new String(resource.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RegionNotFoundException("GeoJSON 파일을 읽을 수 없습니다: " + province.getGeojsonFilePath(), e);
        }
    }

    // 특정 시/도의 GeoJSON 파일 존재 여부 확인
    public boolean hasProvinceGeoJson(String provinceId) {
        Province province = provinceRepository.findById(provinceId).orElse(null);
        if (province == null || province.getGeojsonFilePath() == null) {
            return false;
        }
        
        try {
            Resource resource = new ClassPathResource("static/geojson/" + province.getGeojsonFilePath());
            return resource.exists();
        } catch (Exception e) {
            return false;
        }
    }
}

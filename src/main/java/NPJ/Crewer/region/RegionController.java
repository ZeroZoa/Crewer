package NPJ.Crewer.region;

import NPJ.Crewer.member.Member;
import NPJ.Crewer.region.dto.ActivityRegionRequestDTO;
import NPJ.Crewer.region.dto.CityResponseDTO;
import NPJ.Crewer.region.dto.CommonApiResponse;
import NPJ.Crewer.region.dto.DistrictResponseDTO;
import NPJ.Crewer.region.dto.ProvinceResponseDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/regions")
@RequiredArgsConstructor
public class RegionController {

    private final RegionService regionService;

    // 1. 모든 시/도 목록 조회
    @GetMapping("/provinces")
    public ResponseEntity<CommonApiResponse<List<ProvinceResponseDTO>>> getAllProvinces() {
        List<ProvinceResponseDTO> provinces = regionService.getAllProvinces();
        return ResponseEntity.ok(CommonApiResponse.success(provinces));
    }

    // 2. 특정 시/도 내의 모든 시/군/구 조회
    @GetMapping("/{provinceId}/cities")
    public ResponseEntity<CommonApiResponse<List<CityResponseDTO>>> getCitiesInProvince(@PathVariable String provinceId) {
        List<CityResponseDTO> cities = regionService.getCitiesInProvince(provinceId);
        return ResponseEntity.ok(CommonApiResponse.success(cities));
    }

    // 3. 특정 시/군/구 내에서 행정동 검색
    @GetMapping("/{provinceId}/cities/{cityId}/districts/search")
    public ResponseEntity<CommonApiResponse<List<DistrictResponseDTO>>> searchDistrictsInCity(
            @PathVariable String provinceId,
            @PathVariable String cityId,
            @RequestParam(required = false, defaultValue = "") String query,
            @RequestParam(defaultValue = "1000") int limit) {
        
        List<DistrictResponseDTO> districts = regionService.searchDistrictsInCity(cityId, query, limit);
        return ResponseEntity.ok(CommonApiResponse.success(districts));
    }

    // 3-1. 특정 시/도 내의 모든 행정동 조회 (지도 표시용)
    @GetMapping("/{provinceId}/districts")
    public ResponseEntity<CommonApiResponse<List<DistrictResponseDTO>>> getAllDistrictsInProvince(
            @PathVariable String provinceId) {
        
        List<DistrictResponseDTO> districts = regionService.getAllDistrictsInProvince(provinceId);
        return ResponseEntity.ok(CommonApiResponse.success(districts));
    }

    // 3-2. 특정 시/도 내에서 행정동 검색 (자동완성용)
    @GetMapping("/{provinceId}/districts/search")
    public ResponseEntity<CommonApiResponse<List<DistrictResponseDTO>>> searchDistrictsInProvince(
            @PathVariable String provinceId,
            @RequestParam String query) {
        
        List<DistrictResponseDTO> districts = regionService.searchDistrictsInProvince(provinceId, query);
        return ResponseEntity.ok(CommonApiResponse.success(districts));
    }

    // 4. 행정동 상세 정보 조회 (GeoJSON 포함)
    @GetMapping("/districts/{districtId}")
    public ResponseEntity<CommonApiResponse<DistrictResponseDTO>> getDistrictDetail(
            @PathVariable String districtId) {
        
        DistrictResponseDTO district = regionService.getDistrictDetail(districtId);
        return ResponseEntity.ok(CommonApiResponse.success(district));
    }

    // 5. 사용자 활동 지역 설정
    @PostMapping("/members/activity-region")
    public ResponseEntity<CommonApiResponse<DistrictResponseDTO>> setActivityRegion(
            @AuthenticationPrincipal Member member,
            @RequestBody ActivityRegionRequestDTO request) {
        
        DistrictResponseDTO activityRegion = regionService.setActivityRegion(member, request);
        return ResponseEntity.ok(CommonApiResponse.success(activityRegion, "활동 지역이 성공적으로 설정되었습니다."));
    }

    // 6. 사용자 활동 지역 조회
    @GetMapping("/members/activity-region")
    public ResponseEntity<CommonApiResponse<DistrictResponseDTO>> getActivityRegion(
            @AuthenticationPrincipal Member member) {
        
        DistrictResponseDTO activityRegion = regionService.getActivityRegion(member);
        return ResponseEntity.ok(CommonApiResponse.success(activityRegion));
    }

    // 7. 사용자 활동 지역 수정
    @PutMapping("/members/activity-region")
    public ResponseEntity<CommonApiResponse<DistrictResponseDTO>> updateActivityRegion(
            @AuthenticationPrincipal Member member,
            @RequestBody ActivityRegionRequestDTO request) {
        
        DistrictResponseDTO activityRegion = regionService.setActivityRegion(member, request);
        return ResponseEntity.ok(CommonApiResponse.success(activityRegion, "활동 지역이 성공적으로 수정되었습니다."));
    }

    // 8. 특정 시/도의 GeoJSON 데이터 조회
    @GetMapping("/{provinceId}/geojson")
    public ResponseEntity<CommonApiResponse<String>> getProvinceGeoJson(@PathVariable String provinceId) {
        try {
            String geoJsonData = regionService.getProvinceGeoJson(provinceId);
            return ResponseEntity.ok(CommonApiResponse.success(geoJsonData));
        } catch (RegionNotFoundException e) {
            return ResponseEntity.badRequest().body(CommonApiResponse.error(e.getMessage()));
        }
    }
}

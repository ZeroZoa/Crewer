package NPJ.Crewer.running;


import NPJ.Crewer.member.Member;
import NPJ.Crewer.running.dto.LocationPointDTO;
import NPJ.Crewer.running.dto.RunningRecordCreateDTO;
import NPJ.Crewer.running.dto.RunningRecordResponseDTO;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Component
public class RunningRecordMapper {

    // DTO → Entity 변환 메서드 수정
    public RunningRecord toEntity(RunningRecordCreateDTO runningRecordCreateDTO, Member member) {
        // 1) 기본 필드만 Builder로 설정
        RunningRecord record = RunningRecord.builder()
                .totalDistance(runningRecordCreateDTO.getTotalDistance())
                .totalSeconds(runningRecordCreateDTO.getTotalSeconds())
                .runner(member)
                .build();

        // 2) path 필드는 엔티티가 가진 초기화된 컬렉션에 addAll로 추가
        if (runningRecordCreateDTO.getPath() != null && !runningRecordCreateDTO.getPath().isEmpty()) {
            List<RunningRecord.LocationPoint> points = runningRecordCreateDTO.getPath().stream()
                    .map(lpd -> RunningRecord.LocationPoint.builder()
                            .latitude(lpd.getLatitude())
                            .longitude(lpd.getLongitude())
                            .build())
                    .toList();
            // 엔티티의 내부 리스트에 추가해야 JPA가 관리 가능한 컬렉션이 됩니다.
            record.getPath().addAll(points);
        }

        return record;
    }

    // Entity → DTO 변환은 그대로 사용
    public RunningRecordResponseDTO toDTO(RunningRecord entity) {
        List<LocationPointDTO> pathDTO = entity.getPath().stream()
                .map(p -> new LocationPointDTO(p.getLatitude(), p.getLongitude()))
                .collect(Collectors.toList());
        return new RunningRecordResponseDTO(
                entity.getId(),
                entity.getRunner().getNickname(),
                entity.getTotalDistance(),
                entity.getTotalSeconds(),
                entity.getCreatedAt(),
                pathDTO
        );
    }
}
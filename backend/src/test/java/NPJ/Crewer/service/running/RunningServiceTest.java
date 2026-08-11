package NPJ.Crewer.service.running;

import NPJ.Crewer.domain.member.Member;
import NPJ.Crewer.domain.running.RunningRecord;
import NPJ.Crewer.domain.running.RunningRecordMapper;
import NPJ.Crewer.repository.member.MemberRepository;
import NPJ.Crewer.repository.running.RunningRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RunningServiceTest {

    @Mock
    private RunningRepository runningRepository;
    @Mock
    private MemberRepository memberRepository;
    @Mock
    private RunningRecordMapper runningRecordMapper;

    @InjectMocks
    private RunningService runningService;

    private Member owner;
    private Member stranger;
    private RunningRecord record;

    @BeforeEach
    void setUp() {
        owner = mock(Member.class);
        stranger = mock(Member.class);
        record = RunningRecord.builder()
                .id(1L)
                .runner(owner)
                .totalSeconds(600)
                .totalDistance(2000.0)
                .build();
    }

    @Test
    void 본인의_기록은_삭제할_수_있다() {
        when(owner.getUsername()).thenReturn("runner1");
        when(memberRepository.findById(1L)).thenReturn(Optional.of(owner));
        when(runningRepository.findById(1L)).thenReturn(Optional.of(record));

        runningService.deleteRunningRecord(1L, 1L);

        verify(runningRepository).delete(record);
    }

    @Test
    void 타인의_기록은_삭제할_수_없다() {
        when(owner.getUsername()).thenReturn("runner1");
        when(stranger.getUsername()).thenReturn("runner2");
        when(memberRepository.findById(2L)).thenReturn(Optional.of(stranger));
        when(runningRepository.findById(1L)).thenReturn(Optional.of(record));

        assertThatThrownBy(() -> runningService.deleteRunningRecord(1L, 2L))
                .isInstanceOf(AccessDeniedException.class);

        verify(runningRepository, never()).delete(any());
    }
}

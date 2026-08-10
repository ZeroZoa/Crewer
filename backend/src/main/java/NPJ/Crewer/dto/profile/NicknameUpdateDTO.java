package NPJ.Crewer.dto.profile;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.validator.constraints.Length;

@Getter
@Setter
public class NicknameUpdateDTO {
    @NotEmpty(message = "닉네임을 입력해주세요.")
    @Length(min = 2, max = 10, message = "닉네임은 2자 이상 10자 이하여야 합니다.")
    @Pattern(regexp = "^[가-힣a-zA-Z0-9]*$", message = "닉네임은 한글, 알파벳, 숫자만 사용할 수 있습니다.")
    private String nickname;
}

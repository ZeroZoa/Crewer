package NPJ.Crewer.member;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.validator.constraints.Length;

@Getter
@Setter
public class MemberCreateDTO {
    @NotEmpty(message = "이메일을 입력해주세요.")
    @Email(message = "유효한 이메일 주소를 입력해주세요.")
    private String username; // 이메일 = 로그인 ID

    @NotEmpty(message = "비밀번호를 입력해주세요.")
    @Size(min = 8, message = "비밀번호는 최소 8자 이상이어야 합니다.")
    private String password1;

    @NotEmpty(message = "비밀번호 확인을 입력해주세요.")
    private String password2;

    @NotEmpty(message = "닉네임을 입력해주세요.")
    @Length(max = 8, message = "닉네임은 8자 이내여야 합니다.")
    @Pattern(regexp = "^[가-힣a-zA-Z0-9]*$", message = "닉네임은 한글, 알파벳, 숫자만 사용할 수 있습니다.")
    private String nickname;
}

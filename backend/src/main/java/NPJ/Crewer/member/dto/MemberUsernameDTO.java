package NPJ.Crewer.member.dto;

import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class MemberUsernameDTO {

    @NotEmpty(message = "이메일(아이디)을 입력해주세요.")
    private String username;
}



package NPJ.Crewer.region.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CommonApiResponse<T> {
    private boolean success;
    private T data;
    private String message;

    // 성공 응답 생성 메소드
    public static <T> CommonApiResponse<T> success(T data) {
        return CommonApiResponse.<T>builder()
                .success(true)
                .data(data)
                .build();
    }

    public static <T> CommonApiResponse<T> success(T data, String message) {
        return CommonApiResponse.<T>builder()
                .success(true)
                .data(data)
                .message(message)
                .build();
    }

    // 에러 응답 생성 메소드
    public static <T> CommonApiResponse<T> error(String message) {
        return CommonApiResponse.<T>builder()
                .success(false)
                .message(message)
                .build();
    }

    public static <T> CommonApiResponse<T> error(T data, String message) {
        return CommonApiResponse.<T>builder()
                .success(false)
                .data(data)
                .message(message)
                .build();
    }
}

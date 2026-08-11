package NPJ.Crewer.global.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FileStorageService {

    @Value("${upload.dir}")
    private String uploadDir;

    /**
     * 프로필 이미지를 저장하고 URL을 반환
     */
    public String storeProfileImage(Long memberId, MultipartFile image) throws IOException {
        File directory = new File(uploadDir + "/profile");

        if (!directory.exists()) {
            directory.mkdirs();
        }

        // 클라이언트가 보낸 원본 파일명을 경로에 그대로 쓰지 않는다 (path traversal 방지)
        String fileName = memberId + "_" + UUID.randomUUID() + extractExtension(image.getOriginalFilename());
        Path filePath = Paths.get(uploadDir + "/profile", fileName);
        String fileUrl = "/crewerimages/profile/" + fileName;

        Files.write(filePath, image.getBytes());

        return fileUrl;
    }

    private String extractExtension(String originalFilename) {
        if (originalFilename == null) {
            return "";
        }
        int dotIndex = originalFilename.lastIndexOf('.');
        if (dotIndex < 0) {
            return "";
        }
        // 확장자에도 경로 구분자 등 위험 문자가 섞여 들어오지 못하도록 제한
        return originalFilename.substring(dotIndex).replaceAll("[^a-zA-Z0-9.]", "");
    }
}

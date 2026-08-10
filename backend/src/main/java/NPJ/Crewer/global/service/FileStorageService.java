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

@Service
@RequiredArgsConstructor
public class FileStorageService {

    @Value("${upload.dir}")
    private String uploadDir;

    /**
     * 프로필 이미지를 저장하고 URL을 반환한다.
     */
    public String storeProfileImage(Long memberId, MultipartFile image) throws IOException {
        File directory = new File(uploadDir + "/profile");
        
        if (!directory.exists()) {
            directory.mkdirs();
        }
        
        String fileName = memberId + "_" + image.getOriginalFilename();
        Path filePath = Paths.get(uploadDir + "/profile", fileName);
        String fileUrl = "/crewerimages/profile/" + fileName;

        Files.write(filePath, image.getBytes());

        return fileUrl;
    }
}

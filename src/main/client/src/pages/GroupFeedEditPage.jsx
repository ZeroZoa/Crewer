import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import axios from "axios";

function GroupFeedEditPage() {
    const { id } = useParams(); // URL에서 id 가져오기
    const navigate = useNavigate(); // 페이지 이동을 위한 네비게이션
    const [title, setTitle] = useState("");
    const [content, setContent] = useState("");
    const [maxParticipants, setMaxParticipants] = useState("");

    useEffect(() => {
        const token = localStorage.getItem("token");
        if (!token) {
            alert("로그인이 필요합니다.");
            navigate("/login");
            return;
        }

        if (!id) return;

        axios.get(`http://localhost:8080/groupfeeds/${id}/edit`, {
            headers: { Authorization: `Bearer ${token}` }
        })
            .then(response => {
                setTitle(response.data.title);
                setContent(response.data.content);
                setMaxParticipants(response.data.maxParticipants); // ✅ maxParticipants 값 설정
            })
            .catch(error => {
                console.error("게시글 불러오기 실패:", error);
                alert("게시글을 수정할 권한이 없습니다.");
                navigate(`/groupfeeds/${id}`);
            });
    }, [id, navigate]);

    const handleUpdate = async () => {
        if (!title.trim() || !content.trim() || !maxParticipants) {
            alert("제목, 내용, 최대 참가 인원을 입력하세요.");
            return;
        }

        try {
            await axios.put( // ✅ PUT 요청 (수정 요청)
                `http://localhost:8080/groupfeeds/${id}/edit`,
                {
                    title,
                    content,
                    maxParticipants: parseInt(maxParticipants, 10) || 1, // ✅ 숫자로 변환
                },
                { headers: { Authorization: `Bearer ${localStorage.getItem("token")}` } }
            );

            alert("그룹 피드가 수정되었습니다.");
            navigate(`/groupfeeds/${id}`); // ✅ 수정 후 상세 페이지로 이동
        } catch (error) {
            console.error("게시글 수정 실패:", error);
            alert("게시글 수정에 실패했습니다.");
        }
    };

    return (
        <div className="min-h-screen flex flex-col items-center w-full bg-gray-100 mt-16">
            <div className="bg-white shadow-lg shadow-blue-200 rounded-lg p-4 w-full max-w-3xl flex-grow">
                <h1 className="text-2xl font-bold mb-4">그룹 피드 수정</h1>

                {/* 제목 입력 */}
                <input
                    type="text"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    className="w-full border p-3 rounded mb-4"
                    placeholder="제목을 입력하세요"
                />

                {/* 내용 입력 */}
                <textarea
                    value={content}
                    onChange={(e) => setContent(e.target.value)}
                    className="w-full border p-3 rounded mb-4"
                    rows="6"
                    placeholder="내용을 입력하세요"
                ></textarea>

                {/* 최대 참가 인원 입력 */}
                <input
                    type="number"
                    value={maxParticipants}
                    onChange={(e) => setMaxParticipants(e.target.value)}
                    className="w-full border p-3 rounded mb-4"
                    placeholder="최대 참가 인원을 입력하세요"
                    min="1"
                />

                {/* 수정 완료 버튼 */}
                <button
                    onClick={handleUpdate}
                    className="bg-[#9cb4cd] text-white px-4 py-2 rounded hover:bg-[#b3c7de] transition w-full"
                >
                    수정 완료
                </button>

                {/* 취소 버튼 */}
                <button
                    onClick={() => navigate(`/groupfeeds/${id}`)}
                    className="mt-2 bg-gray-300 text-black px-4 py-2 rounded hover:bg-gray-400 transition w-full"
                >
                    취소
                </button>
            </div>
        </div>
    );
}

export default GroupFeedEditPage;
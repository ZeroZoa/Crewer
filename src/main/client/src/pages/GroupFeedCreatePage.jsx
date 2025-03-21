import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";

const GroupFeedCreatePage = () => {
    // 수정: maxParticipants 초기값을 "2"로 설정하여 슬라이더 기본값과 일치
    const [formData, setFormData] = useState({ title: "", content: "", maxParticipants: "2" });
    const [isSubmitting, setIsSubmitting] = useState(false);
    const navigate = useNavigate();

    // JWT 토큰 가져오는 함수
    const getToken = () => localStorage.getItem("token");

    useEffect(() => {
        if (!getToken()) {
            alert("로그인 후 글쓰기가 가능합니다.");
            navigate("/login");
        }
    }, [navigate]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData({ ...formData, [name]: value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (isSubmitting) return;
        setIsSubmitting(true);

        const token = getToken();
        if (!token) {
            alert("로그인이 필요합니다.");
            navigate("/login");
            return;
        }

        try {
            const response = await fetch("http://localhost:8080/groupfeeds/create", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify({
                    title: formData.title,
                    content: formData.content,
                    // 수정: 문자열을 정수로 변환, 기본값은 2
                    maxParticipants: parseInt(formData.maxParticipants, 10) || 2,
                }),
            });

            if (response.ok) {
                alert("그룹 피드 작성이 완료되었습니다!");
                navigate("/");
            } else {
                const errorText = await response.text();
                alert(`작성 실패: ${errorText}`);
            }
        } catch (error) {
            alert("서버 오류가 발생했습니다.");
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="h-screen flex flex-col items-center w-full mt-16">
            <form
                className="bg-white shadow-lg shadow-blue-200 rounded-lg p-6 w-full max-w-3xl h-full"
                onSubmit={handleSubmit}
            >
                <h2 className="text-2xl font-bold text-center mb-6">그룹 피드 작성</h2>

                {/* 제목 입력 */}
                <div className="mb-4">
                    <label className="block text-gray-700 font-medium mb-2">제목</label>
                    <input
                        type="text"
                        name="title"
                        value={formData.title}
                        onChange={handleChange}
                        required
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#9cb4cd]"
                    />
                </div>

                {/* 내용 입력 */}
                <div className="mb-4">
                    <label className="block text-gray-700 font-medium mb-2">내용</label>
                    <textarea
                        name="content"
                        value={formData.content}
                        onChange={handleChange}
                        required
                        rows="6"
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#9cb4cd]"
                    />
                </div>

                {/* 최대 참가 인원 입력 - 슬라이더로 변경 */}
                <div className="mb-4">
                    <label className="block text-gray-700 font-medium mb-2 ">최대 참가 인원</label>
                    <input
                        type="range"
                        name="maxParticipants"
                        min="2"
                        max="10"
                        value={formData.maxParticipants}
                        onChange={handleChange}
                        required
                        list="tickmarks"
                        className="custom-range w-full"
                    />
                    {/* 눈금 표시 */}
                    <datalist id="tickmarks">
                        <option value="2" label="2"></option>
                        <option value="3" label="3"></option>
                        <option value="4" label="4"></option>
                        <option value="5" label="5"></option>
                        <option value="6" label="6"></option>
                        <option value="7" label="7"></option>
                        <option value="8" label="8"></option>
                        <option value="9" label="9"></option>
                        <option value="10" label="10"></option>
                    </datalist>
                    <div className="text-center mt-2 ">
                        선택된 인원: {formData.maxParticipants}
                    </div>
                </div>

                {/* 작성 버튼 */}
                <button
                    type="submit"
                    disabled={isSubmitting}
                    className="w-full bg-[#9cb4cd] text-black py-2 rounded-md hover:bg-[#b3c7de] focus:outline-none focus:ring-2 focus:ring-[#9cb4cd] mt-4"
                >
                    {isSubmitting ? "작성 중..." : "작성 완료"}
                </button>
            </form>
        </div>
    );
};

export default GroupFeedCreatePage;
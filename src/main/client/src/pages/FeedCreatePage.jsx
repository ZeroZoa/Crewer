import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";

const FeedCreatePage = () => {
    const [formData, setFormData] = useState({
        title: "",
        content: "",
    });

    const navigate = useNavigate();

    useEffect(() => {
        const token = localStorage.getItem("token");
        if (!token) {
            alert("로그인 후 글쓰기가 가능합니다.");
            navigate("/login");
            return;
        }

        // ✅ JWT 토큰에서 사용자 정보 가져오기
        try {
            const payload = JSON.parse(atob(token.split(".")[1]));
            const username = payload.sub || "알 수 없음"; // 🔹 JWT의 subject(sub)에서 username 가져오기
        } catch (error) {
            alert("로그인 정보가 유효하지 않습니다. 다시 로그인해주세요.");
            localStorage.removeItem("token");
            navigate("/login");
        }
    }, [navigate]);

    const handleChange = (e) => {
        setFormData({
            ...formData,
            [e.target.name]: e.target.value,
        });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        const token = localStorage.getItem("token");

        if (!token) {
            alert("로그인이 필요합니다.");
            navigate("/login");
            return;
        }

        try {
            const response = await fetch("http://localhost:8080/feeds/create", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${token}`,
                },
                body: JSON.stringify(formData),
            });

            if (response.ok) {
                alert("피드 작성이 완료되었습니다!");
                navigate("/");
            } else {
                const errorText = await response.text();
                alert(`작성 실패: ${errorText}`);
            }
        } catch (error) {
            alert("서버 오류가 발생했습니다.");
        }
    };

    return (
        <div className="flex items-center justify-center min-h-screen">
            <form className="bg-white p-8 rounded-lg shadow-2xl shadow-blue-200 w-full max-w-lg" onSubmit={handleSubmit}>
                <h2 className="text-2xl font-bold text-center mb-6">피드 작성</h2>

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

                <button
                    type="submit"
                    className="w-full bg-[#9cb4cd] text-black py-2 rounded-md hover:bg-[#b3c7de] focus:outline-none focus:ring-2 focus:ring-[#9cb4cd]"
                >
                    작성 완료
                </button>
            </form>
        </div>
    );
};

export default FeedCreatePage;
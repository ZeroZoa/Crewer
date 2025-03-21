import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";

const FeedCreatePage = () => {
    const [formData, setFormData] = useState({ title: "", content: "" });
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
        setFormData({ ...formData, [e.target.name]: e.target.value });
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
            const response = await fetch("http://localhost:8080/feeds/create", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${token}`,
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
                    disabled={isSubmitting}
                    className="w-full bg-[#9cb4cd] text-black py-2 rounded-md hover:bg-[#b3c7de] focus:outline-none focus:ring-2 focus:ring-[#9cb4cd] mt-4"
                >
                    {isSubmitting ? "작성 중..." : "작성 완료"}
                </button>
            </form>
        </div>
    );
};

export default FeedCreatePage;
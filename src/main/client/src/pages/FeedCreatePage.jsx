import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";

const FeedCreatePage = () => {
    const [formData, setFormData] = useState({
        title: "",
        content: "",
    });

    const [username, setUsername] = useState(""); //사용자 이름 상태 추가
    const navigate = useNavigate();

    useEffect(() => {
        const token = localStorage.getItem("token");
        if (!token) {
            alert("로그인 후 글쓰기가 가능합니다.");
            navigate("/login");
            return;
        }

        //JWT 토큰에서 사용자 정보 가져오기 (변수 선언 없이 바로 사용)
        try {
            const decodedToken = JSON.parse(atob(token.split(".")[1]));
            setUsername(decodedToken.username); // 사용자 이름 저장
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
        <div className="h-screen flex flex-col items-center w-full">
            <form className="bg-white shadow-lg shadow-blue-200 rounded-lg p-6 w-full max-w-3xl h-full" onSubmit={handleSubmit}>
                <h2 className="text-2xl font-bold text-center mb-6">피드 작성</h2>

                {/* 로그인된 사용자 이름 표시 */}
                {username && (
                    <p className="text-center text-gray-600 mb-4">작성자: <span className="font-semibold">{username}</span></p>
                )}

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
                    className="w-full bg-[#9cb4cd] text-black py-2 rounded-md hover:bg-[#b3c7de] focus:outline-none focus:ring-2 focus:ring-[#9cb4cd] mt-4"
                >
                    작성 완료
                </button>
            </form>
        </div>
    );
};

export default FeedCreatePage;
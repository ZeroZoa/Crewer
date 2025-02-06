import React, { useState } from "react";

const LoginPage = () => {
    const [formData, setFormData] = useState({
        username: "", // ✅ email → username 변경
        password: "",
    });
    const [errorMessage, setErrorMessage] = useState("");

    const handleChange = (e) => {
        setFormData({
            ...formData,
            [e.target.name]: e.target.value,
        });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setErrorMessage(""); // 에러 메시지 초기화

        try {
            const response = await fetch("http://localhost:8080/members/login", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(formData),
            });

            if (response.ok) {
                const token = await response.text(); // 서버로부터 JWT 토큰 수신
                localStorage.setItem("token", token); // JWT 토큰 로컬 스토리지에 저장
                alert("로그인 성공!");
                window.location.href = "/"; // 메인 페이지로 리다이렉트
            } else {
                const errorText = await response.text();
                setErrorMessage(`로그인 실패: ${errorText}`);
            }
        } catch (error) {
            setErrorMessage("서버와의 통신 중 오류가 발생했습니다.");
        }
    };

    return (
        <div className="flex items-center justify-center min-h-screen w-full">
            <form
                className="bg-white p-8 rounded-lg shadow-2xl shadow-blue-200 w-full max-w-md"
                onSubmit={handleSubmit}
            >
                <h2 className="text-2xl font-bold text-center mb-6 text-gray-800">
                    로그인
                </h2>

                {errorMessage && (
                    <div className="text-red-500 mb-4">{errorMessage}</div>
                )}

                <div className="mb-4">
                    <label className="block text-gray-700 font-medium mb-2">사용자명 (이메일)</label>
                    <input
                        type="email"
                        name="username"
                        value={formData.username}
                        onChange={handleChange}
                        required
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                </div>

                <div className="mb-4">
                    <label className="block text-gray-700 font-medium mb-2">비밀번호</label>
                    <input
                        type="password"
                        name="password"
                        value={formData.password}
                        onChange={handleChange}
                        required
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                </div>

                <button
                    type="submit"
                    className="w-full bg-[#9cb4cd] text-black py-2 rounded-md hover:bg-[#b3c7de] focus:outline-none focus:ring-2 focus:ring-[#9cb4cd]"
                >
                    로그인
                </button>
            </form>
        </div>
    );
};

export default LoginPage;
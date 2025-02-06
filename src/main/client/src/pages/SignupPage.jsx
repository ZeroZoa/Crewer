import React, { useState } from "react";
import { useNavigate } from "react-router-dom";

const SignupPage = () => {
    const [formData, setFormData] = useState({
        username: "",
        password1: "",
        password2: "",
        nickname: "",
    });
    const [successMessage, setSuccessMessage] = useState("");
    const [errorMessage, setErrorMessage] = useState("");

    const navigate = useNavigate(); // 로그인 페이지로 이동하기 위한 useNavigate 추가

    const handleChange = (e) => {
        setFormData({
            ...formData,
            [e.target.name]: e.target.value,
        });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setErrorMessage("");

        if (formData.password1 !== formData.password2) {
            setErrorMessage("비밀번호가 일치하지 않습니다.");
            return;
        }

        try {
            const response = await fetch("http://localhost:8080/members/register", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(formData),
            });

            if (response.ok) {
                setSuccessMessage("회원가입이 완료되었습니다.");
                setTimeout(() => navigate("/login"), 2000); // ✅ 2초 후 로그인 페이지로 이동
            } else {
                const errorText = await response.text();
                setErrorMessage(`회원가입 실패: ${errorText}`);
            }
        } catch (error) {
            setErrorMessage("서버와 통신 중 오류가 발생했습니다.");
        }
    };

    return (
        <div className="h-screen flex flex-col items-center w-full">
            <form
                className="bg-white shadow-lg shadow-blue-200 rounded-lg p-6 w-full max-w-3xl h-full"
                onSubmit={handleSubmit}
            >
                <h2 className="text-2xl font-bold text-center mb-6 text-gray-800">
                    회원가입
                </h2>

                {successMessage && (
                    <div className="text-green-500 mb-4">{successMessage}</div>
                )}
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
                        name="password1"
                        value={formData.password1}
                        onChange={handleChange}
                        required
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                </div>

                <div className="mb-4">
                    <label className="block text-gray-700 font-medium mb-2">
                        비밀번호 확인
                    </label>
                    <input
                        type="password"
                        name="password2"
                        value={formData.password2}
                        onChange={handleChange}
                        required
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                </div>

                <div className="mb-4">
                    <label className="block text-gray-700 font-medium mb-2">닉네임</label>
                    <input
                        type="text"
                        name="nickname"
                        value={formData.nickname}
                        onChange={handleChange}
                        required
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                </div>

                <button
                    type="submit"
                    className="w-full bg-[#9cb4cd] text-black py-2 rounded-md hover:bg-[#b3c7de] focus:outline-none focus:ring-2 focus:ring-[#9cb4cd] mt-4"
                >
                    회원가입
                </button>
            </form>
        </div>
    );
};

export default SignupPage;
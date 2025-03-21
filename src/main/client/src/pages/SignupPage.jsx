import React, { useState } from "react";
import { useNavigate } from "react-router-dom";

const API_URL = "http://localhost:8080/members";

const SignupPage = () => {
    const [formData, setFormData] = useState({
        username: "",
        password1: "",
        password2: "",
        nickname: "",
    });
    const [message, setMessage] = useState({ type: "", text: "" });
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    const handleChange = (e) => {
        setFormData({
            ...formData,
            [e.target.name]: e.target.value,
        });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage({ type: "", text: "" });

        if (formData.password1 !== formData.password2) {
            setMessage({ type: "error", text: "비밀번호가 일치하지 않습니다." });
            return;
        }

        setLoading(true);
        try {
            const response = await fetch(`${API_URL}/register`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(formData),
            });

            const result = await response.text();

            if (!response.ok) {
                throw new Error(result);
            }

            setMessage({ type: "success", text: "회원가입이 완료되었습니다. 로그인 페이지로 이동합니다." });

            // ✅ 즉시 로그인 페이지로 이동
            navigate("/login");
        } catch (error) {
            console.error("❌ 회원가입 오류:", error);
            setMessage({ type: "error", text: error.message || "회원가입 중 오류가 발생했습니다." });
        } finally {
            // ✅ `setLoading(false);` 실행 보장
            setLoading(false);
        }
    };

    return (
        <div className="h-screen flex flex-col items-center w-full mt-16">
            <form
                className="bg-white shadow-lg shadow-blue-200 rounded-lg p-6 w-full max-w-3xl h-full"
                onSubmit={handleSubmit}
            >
                <h2 className="text-2xl font-bold text-center mb-6 text-gray-800">
                    회원가입
                </h2>

                {message.text && (
                    <div className={`mb-4 ${message.type === "error" ? "text-red-500" : "text-green-500"}`}>
                        {message.text}
                    </div>
                )}

                <div className="mb-4">
                    <label className="block text-gray-700 font-medium mb-2">이메일 (아이디)</label>
                    <input
                        type="email"
                        name="username"
                        value={formData.username}
                        onChange={handleChange}
                        required
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
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
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
                    />
                </div>

                <div className="mb-4">
                    <label className="block text-gray-700 font-medium mb-2">비밀번호 확인</label>
                    <input
                        type="password"
                        name="password2"
                        value={formData.password2}
                        onChange={handleChange}
                        required
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
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
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
                    />
                </div>

                <button
                    type="submit"
                    className={`w-full py-2 mt-4 rounded-md text-black ${
                        loading ? "bg-gray-300 cursor-not-allowed" : "bg-[#9cb4cd] hover:bg-[#b3c7de] focus:ring-[#9cb4cd]"
                    }`}
                    disabled={loading}
                >
                    {loading ? "회원가입 중..." : "회원가입"}
                </button>
            </form>
        </div>
    );
};

export default SignupPage;
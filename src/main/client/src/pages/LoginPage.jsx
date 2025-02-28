import React, { useState } from "react";
import { useNavigate } from "react-router-dom";

const API_URL = "http://localhost:8080/members";

const LoginPage = () => {
    const [formData, setFormData] = useState({
        username: "",
        password: "",
    });
    const [errorMessage, setErrorMessage] = useState("");
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
        setErrorMessage("");
        setLoading(true);

        try {
            console.log("🟢 로그인 요청 시작");

            const response = await fetch(`${API_URL}/login`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(formData),
            });

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`로그인 실패: ${errorText}`);
            }

            const token = await response.text();
            localStorage.setItem("token", token);

            console.log("✅ 로그인 성공! 저장된 토큰:", token);

            // ✅ setTimeout 제거, 바로 navigate 실행
            navigate("/");
        } catch (error) {
            console.error("❌ 로그인 오류:", error);
            setErrorMessage(error.message || "로그인 중 오류가 발생했습니다.");
        } finally {
            // ✅ `setLoading(false);` 실행 보장
            setLoading(false);
        }
    };

    return (
        <div className="h-screen flex flex-col items-center w-full">
            <form
                className="bg-white shadow-lg shadow-blue-200 rounded-lg p-6 w-full max-w-3xl h-full"
                onSubmit={handleSubmit}
            >
                <h2 className="text-2xl font-bold text-center mb-6 text-gray-800">
                    로그인
                </h2>

                {errorMessage && <div className="text-red-500 mb-4">{errorMessage}</div>}

                <div className="mb-4">
                    <label className="block text-gray-700 font-medium mb-2">
                        사용자명 (이메일)
                    </label>
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
                    className={`w-full py-3 mt-4 rounded-md text-black ${
                        loading
                            ? "bg-gray-300 cursor-not-allowed"
                            : "bg-[#9cb4cd] hover:bg-[#b3c7de] focus:ring-[#9cb4cd]"
                    }`}
                    disabled={loading}
                >
                    {loading ? "로그인 중..." : "로그인"}
                </button>
            </form>
        </div>
    );
};

export default LoginPage;
import React from "react";
import { useNavigate } from "react-router-dom";

const NotFoundPage = () => {
    const navigate = useNavigate();

    return (
        <div className="h-screen flex flex-col items-center justify-center px-4">
            <div className="bg-white shadow-xl rounded-2xl p-10 max-w-md w-full text-center">
                <h1 className="text-4xl font-bold text-[#9cb4cd] mb-4">404</h1>
                <p className="text-gray-600 text-lg mb-6">페이지를 찾을 수 없습니다.</p>
                <button
                    onClick={() => navigate("/")}
                    className="mt-4 px-6 py-2 bg-[#9cb4cd] text-white rounded-lg hover:bg-[#89a4bf] transition"
                >
                    홈으로 돌아가기
                </button>
            </div>
        </div>
    );
};

export default NotFoundPage;
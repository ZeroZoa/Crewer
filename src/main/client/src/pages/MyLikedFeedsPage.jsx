import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";

const MyLikedFeedsPage = () => {
    const [feeds, setFeeds] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchLikedFeeds = async () => {
            try {
                const response = await axios.get("http://localhost:8080/profile/me/liked-feeds", {
                    headers: { Authorization: `Bearer ${localStorage.getItem("token")}` },
                });

                setFeeds(response.data);
            } catch (error) {
                console.error("좋아요한 피드 불러오기 실패:", error);
                setError("좋아요한 피드를 불러올 수 없습니다.");
            } finally {
                setLoading(false);
            }
        };

        fetchLikedFeeds();
    }, []);

    if (loading) return <p className="text-center mt-5 text-gray-500">로딩 중...</p>;
    if (error) return <p className="text-center mt-5 text-red-500">{error}</p>;

    return (
        <div className="min-h-screen flex flex-col items-center w-full bg-gray-100">
            <div className="bg-white shadow-lg shadow-blue-200 rounded-lg p-4 w-full max-w-3xl flex-grow">
                <h2 className="text-2xl font-bold text-center mb-6">내가 좋아요한 피드</h2>

                <div className="mt-2 space-y-2">
                    {feeds.length > 0 ? (
                        feeds.map((feed) => (
                            <div
                                key={feed.id}
                                className="bg-[#f5faff] py-5 px-7 rounded-xl shadow-blue-200 shadow-2xl cursor-pointer transition relative mb-2"
                                onClick={() => navigate(`/feeds/${feed.id}`)}
                            >
                                {/* 제목 & 작성자 정렬 */}
                                <div className="flex justify-between items-center">
                                    <h2 className="text-lg font-bold">{feed.title}</h2>
                                    <p className="text-gray-600 text-sm">
                                        {feed.author?.nickname || "알 수 없음"}
                                    </p>
                                </div>
                            </div>
                        ))
                    ) : (
                        <p className="text-gray-500">좋아요한 피드가 없습니다.</p>
                    )}
                </div>
            </div>
        </div>
    );
};

export default MyLikedFeedsPage;
import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { Heart, MessageCircle } from "lucide-react"; // ✅ 좋아요 & 댓글 아이콘 추가

const MyFeedsPage = () => {
    const [feeds, setFeeds] = useState([]); // 내가 작성한 피드 리스트
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchFeeds = async () => {
            try {
                const response = await axios.get("http://localhost:8080/profile/me/feeds", {
                    headers: { Authorization: `Bearer ${localStorage.getItem("token")}` },
                });

                setFeeds(response.data); // ✅ 모든 피드를 한 번에 가져오기
            } catch (error) {
                console.error("피드 불러오기 실패:", error);
                setError("피드를 불러올 수 없습니다.");
            } finally {
                setLoading(false);
            }
        };

        fetchFeeds();
    }, []);

    if (loading) return <p className="text-center mt-5 text-gray-500">로딩 중...</p>;
    if (error) return <p className="text-center mt-5 text-red-500">{error}</p>;

    return (
        <div className="h-screen flex flex-col items-center w-full">
            <div className="bg-white shadow-lg rounded-lg p-6 w-full max-w-3xl h-full">
                <h2 className="text-2xl font-bold text-center mb-6">내가 작성한 피드</h2>

                <div className="mt-4 space-y-2">
                    {feeds.length > 0 ? (
                        feeds.map((feed) => (
                            <div
                                key={feed.id}
                                className="bg-[#f5faff] py-5 px-7 rounded-xl shadow-blue-200 shadow-2xl cursor-pointer transition relative mb-2"
                                onClick={() => navigate(`/feeds/${feed.id}`)}
                            >
                                <div className="flex justify-between items-center">
                                    {/* 제목 */}
                                    <h3 className="text-lg font-semibold">{feed.title}</h3>

                                    {/* ✅ 좋아요 & 댓글 개수 표시 */}
                                    <div className="flex items-center space-x-3">
                                        <div className="flex items-center space-x-1">
                                            <Heart className="w-5 h-5 text-red-500" />
                                            <span className="text-gray-700">{feed.likesCount || 0}</span>
                                        </div>
                                        <div className="flex items-center space-x-1">
                                            <MessageCircle className="w-5 h-5 text-blue-500" />
                                            <span className="text-gray-700">{feed.commentsCount || 0}</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        ))
                    ) : (
                        <p className="text-gray-500 text-center">작성한 피드가 없습니다.</p>
                    )}
                </div>
            </div>
        </div>
    );
};

export default MyFeedsPage;
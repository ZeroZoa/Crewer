import React, { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Plus, Heart } from "lucide-react"; //MessageSquare 제거

const FeedListPage = () => {
    const [feeds, setFeeds] = useState([]);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchFeeds = async () => {
            try {
                const response = await fetch("http://localhost:8080/feeds");
                if (response.ok) {
                    let data = await response.json();
                    data.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
                    setFeeds(data);
                } else {
                    console.error("Failed to fetch feeds");
                }
            } catch (error) {
                console.error("Error fetching feeds:", error);
            }
        };

        fetchFeeds();
    }, []);

    // 날짜 포맷: "YYYY년 M월 D일"
    const formatDate = (date) => {
        const options = { year: "numeric", month: "long", day: "numeric" };
        return new Date(date).toLocaleDateString("ko-KR", options);
    };

    return (
        <div className="min-h-screen flex flex-col items-center w-full">
            <div className="bg-white shadow-lg shadow-blue-200 rounded-lg p-4 w-full max-w-3xl h-full flex-grow mb-10">
                {feeds.map((feed) => (
                    <div
                        key={feed.id}
                        className="bg-[#f5faff] py-5 px-7 rounded-xl shadow-blue-200 shadow-2xl cursor-pointer transition relative mb-3"
                        onClick={() => navigate(`/feeds/${feed.id}`)}
                    >
                        {/* 왼쪽 상단 정렬 */}
                        <div className="flex flex-col items-start -mt-2 -ml-2">
                            <h2 className="text-xl font-bold">{feed.title}</h2>
                            <p className="text-gray-600 text-sm">
                                {formatDate(feed.createdAt)} · {feed.author?.nickname || "알 수 없음"}
                            </p>
                        </div>

                        {/* 좋아요 (오른쪽 아래 정렬) */}
                        <div className="absolute bottom-3 right-4 flex items-center space-x-1.5 -mr-1 -mb-1">
                            <Heart className="w-4 h-4 text-red-500" />
                            <span className="text-gray-700">{feed.likes?.length || 0}</span>
                        </div>
                    </div>
                ))}
            </div>

            {/* 플로팅 버튼 */}
            <Link
                to="/feeds/create"
                className="fixed bottom-20 right-6 border-4 border-[#9cb4cd] bg-white text-[#9cb4cd] w-16 h-16 rounded-full flex items-center justify-center shadow-xl hover:bg-[#9cb4cd] hover:text-white focus:outline-none focus:ring-2 focus:ring-[#9cb4cd]"
            >
                <Plus className="w-9 h-9" />
            </Link>
        </div>
    );
};

export default FeedListPage;
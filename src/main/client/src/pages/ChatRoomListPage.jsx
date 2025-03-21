import React, { useEffect, useState } from "react";
import axios from "axios";
import { useNavigate } from "react-router-dom";

const ChatRoomListPage = () => {
    const [chatRooms, setChatRooms] = useState([]); // 타입 제거!
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchChatRooms = async () => {
            try {
                const response = await axios.get("http://localhost:8080/chat", {
                    headers: {
                        Authorization: `Bearer ${localStorage.getItem("token")}`,
                    },
                });
                setChatRooms(response.data);
            } catch (error) {
                console.error("채팅방 목록 불러오기 실패:", error);
                setError("채팅방 정보를 불러올 수 없습니다.");
            } finally {
                setLoading(false);
            }
        };

        fetchChatRooms();
    }, []);

    if (loading) return <p className="text-center mt-5 text-gray-500">로딩 중...</p>;
    if (error) return <p className="text-center mt-5 text-red-500">{error}</p>;

    return (
        <div className="h-screen flex flex-col items-center w-full">
            <div className="bg-white shadow-lg rounded-lg p-6 w-full max-w-3xl h-full">
                <h1 className="text-3xl font-bold text-[#9cb4cd] mb-6">내가 참여한 채팅방</h1>

                <div className="mt-4 space-y-2">
                    {chatRooms.length > 0 ? (
                        chatRooms.map((room) => (
                            <div
                                key={room.id}
                                onClick={() => navigate(`/chat/${room.id}`)}
                                className="bg-[#f5faff] py-5 px-7 rounded-xl shadow-blue-200 shadow-2xl cursor-pointer transition relative mb-2"
                            >
                                <div className="flex justify-between items-center">
                                    <h3 className="text-lg font-semibold">{room.name}</h3>
                                    <p className="text-sm text-gray-600">
                                        {room.currentParticipants} / {room.maxParticipants} 명
                                    </p>
                                </div>
                                <div className="w-full bg-gray-200 rounded-full h-2 mt-3">
                                    <div
                                        className="bg-[#9cb4cd] h-2 rounded-full transition-all duration-300"
                                        style={{
                                            width: `${(room.currentParticipants / room.maxParticipants) * 100}%`,
                                        }}
                                    ></div>
                                </div>
                            </div>
                        ))
                    ) : (
                        <p className="text-gray-500 text-center">참여 중인 채팅방이 없습니다.</p>
                    )}
                </div>
            </div>
        </div>
    );
};

export default ChatRoomListPage;
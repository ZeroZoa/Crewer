import React, { useEffect, useState, useCallback } from "react";
import { useParams, useNavigate } from "react-router-dom";
import axios from "axios";
import { Heart, MoreVertical, Users } from "lucide-react";

function GroupFeedDetailPage() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [groupFeed, setGroupFeed] = useState(null);
    const [comments, setComments] = useState([]);
    const [newComment, setNewComment] = useState("");
    const [isLiked, setIsLiked] = useState(false);
    const token = localStorage.getItem("token");
    const [showOptions, setShowOptions] = useState(false);

    // 그룹 피드 상세 정보 가져오기
    const fetchGroupFeedDetails = useCallback(async () => {
        try {
            const response = await axios.get(`http://localhost:8080/groupfeeds/${id}`);
            setGroupFeed(response.data);
        } catch (error) {
            console.error("그룹 피드 불러오기 실패:", error);
        }
    }, [id]);

    // 댓글 가져오기
    const fetchComments = useCallback(async () => {
        try {
            const response = await axios.get(`http://localhost:8080/groupfeeds/${id}/comments`);
            // 댓글 순서를 최신순(역순)으로 정렬
            setComments(response.data.reverse());
        } catch (error) {
            console.error("댓글 불러오기 실패:", error);
        }
    }, [id]);

    // 좋아요 상태 가져오기
    const fetchLikeStatus = useCallback(async () => {
        if (!token) {
            setIsLiked(false);
            return;
        }
        try {
            const response = await axios.get(`http://localhost:8080/groupfeeds/${id}/like/status`, {
                headers: { Authorization: `Bearer ${token}` },
            });
            setIsLiked(response.data);
        } catch (error) {
            console.error("좋아요 상태 불러오기 실패:", error);
            setIsLiked(false);
        }
    }, [id, token]);

    useEffect(() => {
        fetchGroupFeedDetails();
        fetchComments();
        fetchLikeStatus();
    }, [fetchGroupFeedDetails, fetchComments, fetchLikeStatus]);

    // 좋아요 토글
    const toggleLike = async () => {
        if (!token) {
            alert("로그인이 필요합니다.");
            return;
        }
        try {
            await axios.post(
                `http://localhost:8080/groupfeeds/${id}/like`,
                {},
                { headers: { Authorization: `Bearer ${token}` } }
            );
            await fetchLikeStatus();
        } catch (error) {
            console.error("좋아요 실패:", error);
        }
    };

    // 참여 버튼 클릭 시: 참여 여부 확인 없이 무조건 서버에 참여 처리 요청 후,
    // 반환된 ChatRoom의 UUID로 채팅방 페이지로 리다이렉트
    const toggleParticipation = async () => {
        if (!token) {
            alert("로그인이 필요합니다.");
            return;
        }
        try {
            const response = await axios.post(
                `http://localhost:8080/groupfeeds/${id}/join-chat`,
                {},
                { headers: { Authorization: `Bearer ${token}` } }
            );
            // ChatRoomResponseDTO의 id (UUID)를 받아서, 해당 URL로 이동
            navigate(`/chat/${response.data.id}`);
        } catch (error) {
            alert("참여 처리 중 오류 발생");
        }
    };

    // 날짜 포맷 함수
    const formatDate = (dateString) => {
        const date = new Date(dateString);
        return isNaN(date.getTime()) ? "날짜 오류" : date.toLocaleString("ko-KR");
    };

    // 댓글 작성
    const handleCommentSubmit = async () => {
        if (!newComment.trim()) {
            alert("댓글을 입력하세요.");
            return;
        }
        if (!token) {
            alert("로그인이 필요합니다.");
            return;
        }
        try {
            const response = await axios.post(
                `http://localhost:8080/groupfeeds/${id}/comments`,
                { content: newComment },
                {
                    headers: {
                        Authorization: `Bearer ${token}`,
                        "Content-Type": "application/json",
                    },
                }
            );
            if (response.status === 201) {
                setNewComment("");
                // 최신 댓글이 위로 오도록 기존 댓글 리스트에 새 댓글 추가
                setComments((prevComments) => [response.data, ...prevComments]);
            }
        } catch (error) {
            alert("댓글 작성에 실패했습니다.");
        }
    };

    // 옵션 메뉴 토글 함수
    const toggleOptions = () => {
        setShowOptions(!showOptions);
    };

    // 수정 페이지 이동 함수
    const handleEdit = () => {
        navigate(`/groupfeeds/${id}/edit`);
    };

    const handleDelete = async () => {
        const confirmDelete = window.confirm("정말 삭제하시겠습니까?");
        if (!confirmDelete) return;
        if (!token) {
            alert("로그인이 필요합니다.");
            return;
        }
        try {
            await axios.delete(`http://localhost:8080/groupfeeds/${id}`, {
                headers: {
                    Authorization: `Bearer ${token}`,
                    "Content-Type": "application/json",
                },
            });
            alert("게시글이 삭제되었습니다.");
            navigate("/");
        } catch (error) {
            alert("게시글 삭제 권한이 없습니다.");
        }
    };

    if (!groupFeed) return <p>로딩 중...</p>;

    return (
        <div className="min-h-screen flex flex-col items-center w-full bg-gray-100 mt-16">
            <div className="bg-white shadow-lg shadow-blue-200 rounded-lg p-4 w-full max-w-3xl flex-grow">
                {/* 제목 및 작성자 정보 */}
                <div className="flex justify-between items-center">
                    <div className="text-left">
                        <h1 className="text-3xl font-bold">{groupFeed.title}</h1>
                        <p className="text-sm text-gray-500 mt-2">
                            작성자: {groupFeed.authorNickname || "알 수 없음"}
                            <br />
                            {formatDate(groupFeed.createdAt)}
                        </p>
                    </div>
                    <div className="relative">
                        <button onClick={toggleOptions} className="hover:text-gray-500 transition">
                            <MoreVertical className="w-6 h-6 text-gray-700" />
                        </button>
                        {/* 옵션 메뉴 */}
                        {showOptions && (
                            <div className="absolute right-0 mt-2 w-28 bg-white border border-gray-300 shadow-lg rounded-lg text-sm">
                                <button onClick={handleEdit} className="block w-full text-left px-4 py-2 hover:bg-gray-100">
                                    수정
                                </button>
                                <button onClick={handleDelete} className="block w-full text-left px-4 py-2 text-red-500 hover:bg-gray-100">
                                    삭제
                                </button>
                            </div>
                        )}
                    </div>
                </div>
                <hr className="border-t-[1px] border-[#9cb4cd] my-4" />

                {/* 본문 */}
                <p className="text-gray-700">{groupFeed.content}</p>
                <hr className="border-t-[1px] border-[#9cb4cd] my-4" />

                {/* 좋아요 및 참여 버튼 */}
                <div className="mt-3 flex justify-between">
                    {/* 참여 버튼 */}
                    <button
                        onClick={toggleParticipation}
                        className={`flex items-center space-x-2 px-3 mb-3 rounded-lg border transition ${
                            // isParticipant는 사용하지 않고, 참여 처리 후 바로 리다이렉트
                            "bg-[#9cb4cd] text-white"
                        }`}
                    >
                        <Users className="w-6 h-6" />
                        <span>Crew 참여하기</span>
                    </button>
                    {/* 좋아요 버튼 */}
                    <div className="mb-3 flex justify-end">
                        <button
                            onClick={toggleLike}
                            className={`flex items-center space-x-2 px-2 py-2 rounded-lg border transition ${
                                isLiked ? "bg-[#9cb4cd] text-white" : "bg-white text-[#9cb4cd] border-[#9cb4cd]"
                            }`}
                        >
                            <Heart
                                className={`w-7 h-7 transition ${
                                    isLiked ? "fill-white stroke-white" : "stroke-[#9cb4cd]"
                                }`}
                            />
                        </button>
                    </div>
                </div>

                {/* 댓글 입력 및 목록 영역 */}
                <div className="my-4 w-full">
                    <div className="flex justify-between items-center">
                        <h2 className="text-xl font-bold">댓글 {comments.length}</h2>
                    </div>
                    <textarea
                        value={newComment}
                        onChange={(e) => setNewComment(e.target.value)}
                        className="border w-full p-3 rounded mt-2"
                        rows="3"
                        placeholder="댓글을 입력하세요"
                    ></textarea>
                    <button
                        onClick={handleCommentSubmit}
                        className="bg-[#9cb4cd] text-white px-4 py-2 rounded mt-2 w-full"
                    >
                        댓글 추가
                    </button>
                    {/* 댓글 목록 */}
                    <ul className="mt-4 w-full">
                        {comments.map((comment) => (
                            <li key={comment.id} className="border-b py-2">
                                <p>{comment.content}</p>
                                <p className="text-sm text-gray-400">
                                    {comment.authorNickname || "익명"} | {formatDate(comment.createdAt)}
                                </p>
                            </li>
                        ))}
                    </ul>
                </div>
            </div>
        </div>
    );
}

export default GroupFeedDetailPage;
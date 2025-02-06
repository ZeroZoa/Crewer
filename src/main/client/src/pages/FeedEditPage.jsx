import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import axios from "axios";

function FeedEditPage() {
    const { id } = useParams();
    const [title, setTitle] = useState("");
    const [content, setContent] = useState("");

    useEffect(() => {
        axios
            .get(`http://localhost:8080/feeds/${id}`)
            .then((response) => {
                setTitle(response.data.title);
                setContent(response.data.content);
            })
            .catch((error) => console.error("Error fetching feed:", error));
    }, [id]);

    const handleSubmit = () => {
        axios
            .put(`http://localhost:8080/feeds/${id}`, {
                title,
                content,
            })
            .then(() => {
                alert("피드가 수정되었습니다.");
                window.location.href = "/";
            })
            .catch((error) => console.error("Error updating feed:", error));
    };

    return (
        <div className="h-screen flex flex-col items-center w-full">
            <div className="bg-white shadow-lg shadow-blue-200 rounded-lg p-6 w-full max-w-3xl h-full">
                <h1 className="text-3xl font-bold mb-6 text-gray-800">피드 수정</h1>
                <input
                    type="text"
                    placeholder="제목"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 mb-4"
                />
                <textarea
                    placeholder="내용"
                    value={content}
                    onChange={(e) => setContent(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 mb-4"
                    rows="5"
                ></textarea>
                <button
                    onClick={handleSubmit}
                    className="w-full bg-[#9cb4cd] text-black py-2 rounded-md hover:bg-[#b3c7de] focus:outline-none focus:ring-2 focus:ring-[#9cb4cd]"
                >
                    수정 완료
                </button>
            </div>
        </div>
    );
}

export default FeedEditPage;
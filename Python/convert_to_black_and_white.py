import cv2
import sys
from PIL import Image
import subprocess
import os

def convert_to_black_and_white(input_path, output_path_mp4, output_path_gif):

    # gifファイル作成用イメージリスト
    images =[]  

    # 動画ファイルのキャプチャー
    cap = cv2.VideoCapture(input_path)

    # フレームの幅取得
    width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)

    # フレームの高さ取得
    height = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)

    # 動画ファイルのフレームレート取得
    fps = cap.get(cv2.CAP_PROP_FPS)

    # 保存用動画ファイルのフォーマット設定
    fourcc = cv2.VideoWriter_fourcc('m', 'p', '4', 'v')
    out = cv2.VideoWriter(output_path_mp4, fourcc, fps, (int(width), int(height))) 

    # 動画を1コマずつ取り込んで処理
    while cap.isOpened():
        ret, frame = cap.read()  # キャプチャー画像の取り込み
        if ret:
            # グレースケール変換
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

            # BGR変換(動画ファイルとチャンネル数を合わせるため)
            bgr = cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)

            # VideoWriterにフレームを追加
            out.write(bgr)

            # gifファイル作成用イメージリストにフレームを追加
            images.append(Image.fromarray(cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)))


        else:  # キャプチャー画像がない場合はループ終了
            break

    cap.release()  # 再生画像をクローズ
    out.release()  # 出力動画ファイルをクローズ

    # gif動画保存
    images[0].save(output_path_gif, save_all=True, append_images=images[1:], optimize=False, duration=1000/fps, loop=0) 

    print("Conversion complete")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python convert_to_black_and_white.py <input_video_path> <output_mp4_path> <output_gif_path>")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path_mp4 = sys.argv[2]
    output_path_gif = sys.argv[3]
    convert_to_black_and_white(input_path, output_path_mp4, output_path_gif)
    print("Script execution complete")
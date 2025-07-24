from flask import Flask, request, send_file, jsonify
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import io
import textwrap
import os
import traceback 

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False


BASE_DIR = os.path.dirname(os.path.abspath(__file__))


TEMPLATE_FILENAME = "template.png"
FONT_FILENAME = "BebasNeue-Regular.ttf" 

TEMPLATE_PATH = os.path.join(BASE_DIR, TEMPLATE_FILENAME)
FONT_PATH = os.path.join(BASE_DIR, FONT_FILENAME)


def check_file_exists(path, file_description):
    """Verilen yoldaki dosyanın var olup olmadığını kontrol eder."""
    if not os.path.exists(path):
        error_message = f"KRİTİK HATA: '{file_description}' dosyası bulunamadı! Aranan yol: {path}"
        print(error_message)
       
        raise FileNotFoundError(error_message)
    print(f"Başarılı: '{file_description}' dosyası bulundu -> {path}")


try:
    check_file_exists(TEMPLATE_PATH, "Şablon PNG")
    check_file_exists(FONT_PATH, "Font Dosyası")
except FileNotFoundError:

    exit()


def create_post_image(background_bytes, title_text, content_text):
    try:
        background = Image.open(io.BytesIO(background_bytes))
        template = Image.open(TEMPLATE_PATH)

        template_size = template.size
        background = background.resize(template_size, Image.Resampling.LANCZOS)
        background.paste(template, (0, 0), mask=template)
        
        final_image = background
        draw = ImageDraw.Draw(final_image)
        
     
        font_title = ImageFont.truetype(FONT_PATH, size=70)
        font_content = ImageFont.truetype(FONT_PATH, size=50)

        # Başlığı yaz (Beyaz renk, siyah dış çizgi ile)
        title_box = (60, 60, 1020, 200) 
        draw.text((title_box[0], title_box[1]), title_text, font=font_title, fill="white", stroke_width=2, stroke_fill="black")

        
        lines = textwrap.wrap(content_text, width=38) 
        current_h = 400
        for line in lines:
            draw.text((140, current_h), line, font=font_content, fill="white", stroke_width=2, stroke_fill="black")
            current_h += font_content.getbbox(line)[3] + 15 # Satır aralığı

        img_buffer = io.BytesIO()
        final_image.save(img_buffer, format='JPEG', quality=90)
        img_buffer.seek(0)
        
        return img_buffer
    except Exception as e:
        print("--- GÖRÜNTÜ İŞLEME İÇİNDE HATA ---")
        traceback.print_exc() 
        print("---------------------------------")
        return None
@app.route('/create-post-image', methods=['POST'])
def handle_request():
    print("Flutter'dan /create-post-image isteği geldi!")
    
    if 'background_image' not in request.files or 'title' not in request.form or 'content' not in request.form:
        return jsonify({"error": "Gerekli parametreler eksik."}), 400

    background_file = request.files['background_image']
    title = request.form['title']
    content = request.form['content']
    
    processed_image = create_post_image(background_file.read(), title, content)

    if processed_image:
        print("Görsel başarıyla oluşturuldu ve geri gönderiliyor.")
        return send_file(processed_image, mimetype='image/jpeg')
    else:
        return jsonify({"error": "Sunucuda görsel işlenirken bir hata oluştu."}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
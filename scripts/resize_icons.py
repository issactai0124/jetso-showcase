import os
from PIL import Image

base_icon_path = r"C:\Users\User\.gemini\antigravity\brain\84800c0b-574c-4c61-b763-5dcdd29b490d\app_icon_base_1772511679379.png"
output_dir = r"e:\local\code\jetso-showcase\web\icons"

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

sizes = [192, 512]

def resize_icon(image, size, output_name):
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(os.path.join(output_dir, output_name), "PNG")
    print(f"Created {output_name} ({size}x{size})")

def create_maskable(image, size, output_name):
    # For maskable icons, we center the icon and add padding (approx 80% scale)
    # per PWA best practices to avoid cropping important parts.
    scaling_factor = 0.8
    icon_content_size = int(size * scaling_factor)
    
    # Create a background matches the icon's background (or just use transparent if the icon handles it)
    # The generated icon has a solid dark background, so we just scale it.
    maskable = Image.new("RGBA", (size, size), (0, 0, 0, 0)) # Transparent base
    
    # Get the source image and resize it to the safe area
    icon_content = image.resize((icon_content_size, icon_content_size), Image.Resampling.LANCZOS)
    
    # Paste centered
    offset = (size - icon_content_size) // 2
    maskable.paste(icon_content, (offset, offset))
    
    maskable.save(os.path.join(output_dir, output_name), "PNG")
    print(f"Created maskable {output_name} ({size}x{size})")

try:
    with Image.open(base_icon_path) as img:
        img = img.convert("RGBA")
        for s in sizes:
            resize_icon(img, s, f"Icon-{s}.png")
            create_maskable(img, s, f"Icon-maskable-{s}.png")
except Exception as e:
    print(f"Error: {e}")

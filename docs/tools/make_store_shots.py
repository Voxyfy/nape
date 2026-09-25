"""App Store ekran görüntüleri: üstte başlık, altta cihaz çerçevesi içinde ekran.
Kullanım: python3 docs/tools/make_store_shots.py --lang tr --src <ham görüntü klasörü> --out store/tr
Ham klasörde beklenen dosyalar: leaning.png upright.png welcome.png lock.png watch.png
Çıktı: 6.9" (1320×2868) ve 6.5" (1242×2688) klasörleri, alfa kanalsız PNG."""
import argparse, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

CAPTIONS = {
    'en': [
        ('leaning',  'Screen Time\nfor your neck.',      'Nape reads your AirPods and shows how far you lean.'),
        ('upright',  'Sit up.\nIt notices.',              'Green when upright, orange when you drop past your threshold.'),
        ('today',    'Your day,\nin minutes.',            'Time leaning, average load on your neck, and a nudge count.'),
        ('island',   'Always\nin view.',                  'Your tilt lives in the Dynamic Island and on the Lock Screen.'),
        ('watch',    'On your\nwrist.',                   'Nudges reach your Apple Watch. A complication shows your tilt.'),
        ('welcome',  'Nothing leaves\nyour iPhone.',      'No account, no server, no analytics. Open source.'),
    ],
    'tr': [
        ('leaning',  'Boynunuz için\nEkran Süresi.',      'Nape, AirPods\'unuzu okur ve ne kadar eğildiğinizi gösterir.'),
        ('upright',  'Dik oturun.\nFark eder.',           'Dikken yeşil, eşiği geçince turuncu.'),
        ('today',    'Gününüz,\ndakika dakika.',          'Eğik süre, boynunuza binen ortalama yük ve uyarı sayısı.'),
        ('island',   'Hep\ngözünüzün önünde.',            'Eğiminiz Dynamic Island\'da ve Kilit Ekranı\'nda.'),
        ('watch',    'Bileğinizde.',                      'Uyarılar Apple Watch\'a ulaşır. Komplikasyon eğiminizi gösterir.'),
        ('welcome',  'Hiçbir şey\niPhone\'unuzdan çıkmaz.', 'Hesap yok, sunucu yok, analitik yok. Açık kaynak.'),
    ],
}
SIZES = {'6.9': (1320, 2868), '6.5': (1242, 2688)}
FONT = '/System/Library/Fonts/SFNS.ttf'

def font(size, weight='Bold'):
    f = ImageFont.truetype(FONT, size)
    try: f.set_variation_by_name(weight)
    except Exception: pass
    return f

def background(W, H, tint):
    bg = Image.new('RGB', (W, H), (11, 11, 14))
    glow = Image.new('RGB', (W, H), (0, 0, 0)); gd = ImageDraw.Draw(glow)
    gd.ellipse([-W * 0.2, H * 0.55, W * 1.2, H * 1.35], fill=tint)
    glow = glow.filter(ImageFilter.GaussianBlur(260))
    return Image.blend(bg, Image.composite(glow, bg, glow.convert('L').point(lambda v: min(255, v * 2))), 0.35)

def rounded_mask(size, r):
    m = Image.new('L', size, 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=r, fill=255); return m

def phone_frame(shot, width):
    """Ekran görüntüsünü ince koyu çerçeveli, yuvarlak köşeli bir cihaza oturtur."""
    bezel = int(width * 0.018); r = int(width * 0.135)
    sw = width - 2 * bezel; sh = int(shot.height * sw / shot.width)
    screen = shot.resize((sw, sh), Image.LANCZOS)
    dev = Image.new('RGBA', (width, sh + 2 * bezel), (0, 0, 0, 0))
    ImageDraw.Draw(dev).rounded_rectangle([0, 0, width - 1, dev.height - 1], radius=r + bezel, fill=(28, 28, 32, 255))
    scr = Image.new('RGBA', screen.size, (0, 0, 0, 0)); scr.paste(screen, (0, 0)); scr.putalpha(rounded_mask(screen.size, r))
    dev.alpha_composite(scr, (bezel, bezel))
    return dev

def watch_frame(shot, width):
    r = int(width * 0.22); bezel = int(width * 0.06)
    sw = width - 2 * bezel; sh = int(shot.height * sw / shot.width)
    screen = shot.resize((sw, sh), Image.LANCZOS)
    dev = Image.new('RGBA', (width, sh + 2 * bezel), (0, 0, 0, 0))
    ImageDraw.Draw(dev).rounded_rectangle([0, 0, width - 1, dev.height - 1], radius=r + bezel, fill=(28, 28, 32, 255))
    scr = Image.new('RGBA', screen.size, (0, 0, 0, 0)); scr.paste(screen, (0, 0)); scr.putalpha(rounded_mask(screen.size, r))
    dev.alpha_composite(scr, (bezel, bezel))
    return dev

def island_crop(full):
    W, H = full.size; return full.crop((W // 2 - 360, 0, W // 2 + 360, 210))

def render(kind, head, sub, src, W, H):
    orange = kind in ('leaning', 'island'); tint = (120, 60, 0) if orange else (0, 90, 40)
    img = background(W, H, tint).convert('RGBA')
    d = ImageDraw.Draw(img)
    # Başlık
    hf = font(int(W * 0.082)); sf = font(int(W * 0.034), 'Medium')
    y = int(H * 0.06)
    for line in head.split('\n'):
        d.text((W // 2, y), line, font=hf, fill=(245, 245, 247), anchor='ma'); y += int(W * 0.095)
    y += int(W * 0.012)
    # Alt başlık, satır kaydırma
    words = sub.split(); lines = []; cur = ''
    for w in words:
        t = (cur + ' ' + w).strip()
        if d.textlength(t, font=sf) > W * 0.82: lines.append(cur); cur = w
        else: cur = t
    lines.append(cur)
    for line in lines:
        d.text((W // 2, y), line, font=sf, fill=(160, 160, 168), anchor='ma'); y += int(W * 0.045)
    top = y + int(H * 0.03)

    if kind == 'watch':
        dev = watch_frame(src['watch'], int(W * 0.56))
        img.alpha_composite(shadow(dev), ((W - dev.width) // 2, top + int(H * 0.12) + 40))
        img.alpha_composite(dev, ((W - dev.width) // 2, top + int(H * 0.12)))
    elif kind == 'island':
        # Kilit ekranı: canlı etkinlik kartı gerçek bağlamında görünür
        dev = phone_frame(src['lock'], int(W * 0.80))
        img.alpha_composite(shadow(dev), ((W - dev.width) // 2, top + 40)); img.alpha_composite(dev, ((W - dev.width) // 2, top))
    else:
        key = {'today': 'leaning', 'leaning': 'leaning', 'upright': 'upright', 'welcome': 'welcome'}[kind]
        dev = phone_frame(src[key], int(W * 0.80))
        img.alpha_composite(shadow(dev), ((W - dev.width) // 2, top + 40)); img.alpha_composite(dev, ((W - dev.width) // 2, top))
    return img.convert('RGB')

def shadow(dev):
    sh = Image.new('RGBA', dev.size, (0, 0, 0, 0)); sh.paste((0, 0, 0, 170), (0, 0, dev.width, dev.height), dev.split()[3])
    pad = 120; big = Image.new('RGBA', (dev.width + 2 * pad, dev.height + 2 * pad), (0, 0, 0, 0)); big.alpha_composite(sh, (pad, pad))
    return big.filter(ImageFilter.GaussianBlur(50)).crop((pad, pad, pad + dev.width, pad + dev.height))

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--lang', required=True); ap.add_argument('--src', required=True); ap.add_argument('--out', required=True)
    a = ap.parse_args()
    src = {k: Image.open(os.path.join(a.src, f'{k}.png')).convert('RGB') for k in ['leaning', 'upright', 'welcome', 'lock', 'watch']}
    for name, (W, H) in SIZES.items():
        out = os.path.join(a.out, name); os.makedirs(out, exist_ok=True)
        for i, (kind, head, sub) in enumerate(CAPTIONS[a.lang], 1):
            if name == '6.5':
                img = render(kind, head, sub, src, *SIZES['6.9']).resize((W, H), Image.LANCZOS)
            else:
                img = render(kind, head, sub, src, W, H)
            img.save(os.path.join(out, f'{i:02d}-{kind}.png'))
    print('ok', a.lang)

if __name__ == '__main__':
    main()

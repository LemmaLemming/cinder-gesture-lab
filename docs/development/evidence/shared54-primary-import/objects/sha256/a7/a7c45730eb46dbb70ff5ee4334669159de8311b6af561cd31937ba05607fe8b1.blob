"""Author Cinder A1-L1 cutouts; original pixel shapes, no source-image crops.
Run from this directory: python3 build_cutouts.py
"""
from pathlib import Path
from PIL import Image, ImageDraw
import math

OUT = Path(__file__).resolve().parent
PAL = {'ink':(20,20,20,255), 'coal':(39,39,39,255), 'shade':(67,67,67,255), 'mid':(105,105,105,255), 'silver':(147,147,147,255), 'light':(193,193,193,255), 'white':(231,231,231,255)}

def canvas(w,h):
    im=Image.new('RGBA',(w,h),(0,0,0,0)); return im,ImageDraw.Draw(im)
def poly(d, points, c): d.polygon(points,fill=PAL[c])
def rect(d, box,c): d.rectangle(box,fill=PAL[c])
def star(d,x,y,r,c='white'):
    # Handmade celestial decoration, intentionally no actionable outline.
    pts=[]
    for i in range(10):
        a=-math.pi/2+i*math.pi/5; rr=r if i%2==0 else r*.42
        pts.append((round(x+math.cos(a)*rr),round(y+math.sin(a)*rr)))
    poly(d,pts,c)
def save(im,name): im.save(OUT/name)

def academic():
    im,d=canvas(48,72)
    # Pointed ceremony hat; pale beard, long restrained embroidered robe.
    poly(d,[(23,0),(33,20),(12,20)],'ink')
    poly(d,[(23,3),(29,17),(15,17)],'shade')
    rect(d,(12,18,34,20),'silver'); star(d,23,12,2,'light')
    poly(d,[(17,22),(29,22),(31,30),(28,37),(18,37),(15,29)],'mid')
    rect(d,(17,23,30,24),'light'); rect(d,(27,26,29,27),'ink')
    poly(d,[(16,29),(20,29),(23,32),(30,28),(31,34),(24,47),(17,40)],'white')
    poly(d,[(17,32),(19,33),(21,43),(18,40)],'silver')
    # Supporting academic quietly indicates the journey board.
    poly(d,[(13,34),(17,38),(13,51),(7,50),(4,45),(6,41)],'ink')
    poly(d,[(14,36),(12,45),(6,45),(7,42)],'shade')
    poly(d,[(29,35),(34,33),(39,23),(42,24),(39,38),(34,45),(29,44)],'coal')
    poly(d,[(39,24),(40,19),(42,18),(42,23),(44,22),(44,26),(40,28)],'light')
    poly(d,[(15,37),(31,36),(34,51),(38,67),(11,67),(13,54)],'ink')
    poly(d,[(16,39),(20,43),(24,46),(28,42),(30,39),(32,55),(35,64),(14,64)],'shade')
    poly(d,[(16,43),(18,47),(17,59),(15,63)],'silver')
    poly(d,[(28,44),(29,45),(32,63),(30,63)],'mid')
    rect(d,(23,47,24,63),'light'); star(d,21,52,2,'light'); star(d,28,58,2,'silver')
    rect(d,(11,66,37,67),'silver'); rect(d,(14,68,22,70),'ink'); rect(d,(29,68,36,70),'ink')
    save(im,'academic.png')

def worker():
    im,d=canvas(48,72)
    poly(d,[(13,8),(27,5),(32,9),(31,13),(12,14)],'ink');rect(d,(13,9,30,11),'silver');rect(d,(12,12,32,14),'coal')
    poly(d,[(16,15),(30,15),(31,23),(27,29),(18,27),(15,20)],'silver')
    rect(d,(18,16,29,18),'light');rect(d,(27,19,29,20),'ink');rect(d,(21,23,30,24),'coal')
    poly(d,[(14,28),(20,27),(23,31),(27,28),(33,30),(37,42),(32,46),(27,39),(26,45),(13,45),(10,39),(6,42),(4,37)],'light')
    rect(d,(13,29,16,43),'coal');rect(d,(27,30,30,43),'coal')
    poly(d,[(15,35),(29,35),(33,57),(12,57)],'ink')
    poly(d,[(17,37),(28,37),(30,53),(15,53)],'coal');rect(d,(18,43,26,45),'shade')
    # Rolled sleeves and lowered hammer, so this cannot read as an attack tell.
    rect(d,(6,35,10,38),'silver');rect(d,(31,39,35,42),'silver')
    poly(d,[(4,38),(8,40),(7,45),(3,45),(2,42)],'silver')
    rect(d,(5,43,7,56),'shade');rect(d,(1,51,10,54),'coal');rect(d,(1,51,10,51),'silver')
    poly(d,[(14,56),(23,56),(22,65),(19,68),(13,67)],'mid');poly(d,[(25,56),(32,56),(34,65),(32,68),(26,67)],'shade')
    rect(d,(12,67,22,70),'ink');rect(d,(27,67,37,70),'ink');rect(d,(13,67,21,67),'silver');rect(d,(28,67,36,67),'mid')
    save(im,'metalworker.png')

def attendant():
    im,d=canvas(48,72)
    poly(d,[(14,7),(29,6),(33,10),(31,13),(12,13)],'ink');rect(d,(14,8,30,10),'light');rect(d,(12,12,33,14),'coal')
    poly(d,[(16,15),(29,15),(31,21),(28,28),(17,27),(15,21)],'silver');rect(d,(18,16,29,18),'light');rect(d,(27,20,29,21),'ink')
    poly(d,[(14,29),(20,28),(23,32),(27,28),(32,30),(35,42),(31,45),(28,38),(29,49),(13,49),(13,37),(9,43),(5,39)],'light')
    poly(d,[(5,39),(2,31),(6,29),(9,37)],'silver')
    poly(d,[(2,31),(3,23),(9,17),(12,18),(8,24),(7,30)],'light')
    rect(d,(13,31,16,48),'white');rect(d,(27,31,29,47),'white')
    for y in [34,38,42]: rect(d,(17,y,26,y+1),'coal')
    rect(d,(14,47,29,49),'coal');rect(d,(21,47,23,49),'silver')
    poly(d,[(14,50),(22,50),(22,57),(13,57)],'white');poly(d,[(23,50),(29,50),(32,57),(24,57)],'light')
    rect(d,(15,58,20,66),'silver');rect(d,(26,58,30,66),'light')
    rect(d,(15,62,20,63),'coal');rect(d,(26,62,30,63),'coal')
    poly(d,[(14,67),(21,67),(21,70),(10,70),(10,69)],'ink');poly(d,[(26,67),(32,67),(36,69),(36,70),(26,70)],'ink')
    save(im,'launch_attendant.png')

def window():
    im,d=canvas(64,112)
    poly(d,[(4,109),(4,38),(8,26),(15,15),(25,8),(32,5),(39,8),(49,15),(56,26),(60,38),(60,109)],'ink')
    poly(d,[(7,105),(7,38),(11,27),(18,17),(26,11),(32,8),(38,11),(46,17),(53,27),(57,38),(57,105)],'mid')
    poly(d,[(11,102),(11,39),(15,28),(23,20),(32,15),(41,20),(49,28),(53,39),(53,102)],'coal')
    # Quiet divided panes, irregular painted highlights rather than a glow.
    poly(d,[(14,39),(17,29),(24,23),(29,20),(29,47),(14,47)],'shade')
    poly(d,[(34,20),(41,24),(48,30),(50,40),(50,47),(34,47)],'mid')
    rect(d,(14,51,29,73),'shade');rect(d,(34,51,50,73),'mid');rect(d,(14,77,29,99),'shade');rect(d,(34,77,50,99),'shade')
    rect(d,(30,17,33,101),'silver');rect(d,(11,48,53,50),'silver');rect(d,(11,74,53,76),'silver')
    rect(d,(2,106,61,109),'silver');rect(d,(4,109,59,111),'shade')
    save(im,'arched_window.png')

def drape():
    im,d=canvas(80,128)
    rect(d,(0,0,79,119),'ink');rect(d,(2,2,77,117),'coal')
    for x in [4,16,29,48,63,74]:rect(d,(x,4,x+2,112),'shade')
    poly(d,[(2,0),(17,0),(20,14),(27,20),(40,23),(54,18),(62,10),(64,0),(78,0),(74,18),(61,29),(42,34),(26,31),(10,23)],'mid')
    poly(d,[(4,0),(8,0),(13,14),(26,26),(44,29),(63,22),(73,10),(75,0),(79,0),(76,18),(61,29),(42,34),(26,31),(10,23)],'silver')
    # A broad crescent is scenic embroidery, with no pulse or perimeter cue.
    d.ellipse((22,43,52,73),fill=PAL['silver']);d.ellipse((31,38,57,65),fill=PAL['coal'])
    star(d,57,83,5,'mid');star(d,21,94,4,'mid');star(d,59,42,3,'mid')
    poly(d,[(0,114),(40,124),(79,114),(79,120),(40,127),(0,120)],'silver')
    save(im,'celestial_drape.png')

def board():
    im,d=canvas(96,56);rect(d,(0,0,95,55),'coal');rect(d,(0,0,95,2),'silver');rect(d,(0,53,95,55),'shade');rect(d,(0,0,2,55),'mid');rect(d,(93,0,95,55),'mid')
    d.ellipse((10,15,33,38),outline=PAL['light'],width=1)
    poly(d,[(17,18),(20,22),(16,25),(18,29),(23,30),(24,35),(20,34),(15,28),(13,24)],'silver')
    d.ellipse((70,6,85,21),outline=PAL['light'],width=1)
    rect(d,(74,11,76,13),'shade');rect(d,(79,15,81,17),'shade')
    for x,y in [(37,24),(43,22),(49,18),(55,15),(61,12)]:rect(d,(x,y,x+2,y),'silver')
    poly(d,[(63,10),(66,10),(64,13)],'light');star(d,42,8,2,'silver');star(d,77,34,2,'silver')
    d.line([(41,43),(73,43),(83,47),(73,50),(41,50),(41,43)],fill=PAL['silver'],width=1)
    rect(d,(70,43,71,49),'shade')
    save(im,'journey_board.png')

def skyline():
    im,d=canvas(192,96)
    # Source F03: layered tiled roofs, dormers and varied industrial chimneys.
    poly(d,[(0,68),(20,61),(37,68),(59,51),(84,64),(110,52),(140,65),(167,52),(191,62),(191,95),(0,95)],'shade')
    for x,y,w,h in [(9,25,7,42),(30,41,10,26),(51,20,5,39),(76,34,10,28),(99,12,6,45),(122,36,8,26),(147,17,9,43),(177,30,6,29)]:
        rect(d,(x,y,x+w,y+h),'coal');rect(d,(x-2,y,x+w+2,y+3),'mid');rect(d,(x+1,y+4,x+2,y+h),'mid')
    poly(d,[(0,87),(21,69),(47,83),(68,66),(95,87),(125,73),(147,84),(172,69),(191,82),(191,95),(0,95)],'coal')
    for x,y in [(18,76),(64,73),(124,79),(169,76)]:
        poly(d,[(x,y),(x+7,y-7),(x+14,y),(x+14,y+8),(x,y+8)],'shade');rect(d,(x+5,y,x+9,y+6),'ink')
    for y in [89,93]:
        for x in range(0,192,10):rect(d,(x,y,x+6,y),'mid')
    save(im,'rooftop_skyline.png')

def plate():
    im,d=canvas(32,64);rect(d,(0,0,31,63),'mid')
    # Long bands carry material; sparse rivets do not become floor noise.
    rect(d,(0,0,31,3),'silver');rect(d,(0,4,31,5),'coal');rect(d,(0,30,31,32),'shade');rect(d,(0,61,31,63),'coal')
    rect(d,(3,7,4,58),'light');rect(d,(28,7,31,58),'shade')
    for y in [8,20,40,52]:
        for x in [8,23]:rect(d,(x,y,x+1,y+1),'coal');rect(d,(x,y,x,y),'light')
    save(im,'riveted_plate.png')

def quiet_floor():
    im,d=canvas(64,64);d.rectangle((0,0,63,63),fill=(115,115,115,255))
    # Seamless low-contrast stage planks: no rings, pulses, markers or arrows.
    for y in [0,16,32,48]:
        d.line((0,y,63,y),fill=(105,105,105,255),width=1)
        d.line((0,y+1,63,y+1),fill=(118,118,118,255),width=1)
    for x,y in [(0,1),(32,17),(16,33),(48,49)]:
        d.line((x,y,x,y+14),fill=(107,107,107,255),width=1)
    for x,y,length in [(7,6,9),(34,10,13),(3,24,12),(46,21,8),(22,38,8),(42,44,11),(5,56,8),(29,60,11)]:
        d.line((x,y,x+length,y),fill=(112,112,112,255),width=1)
        d.point((x+2,y+2),fill=(118,118,118,255))
    save(im,'quiet_floor.png')

if __name__=='__main__':
    for fn in [academic,worker,attendant,window,drape,board,skyline,plate,quiet_floor]:fn()

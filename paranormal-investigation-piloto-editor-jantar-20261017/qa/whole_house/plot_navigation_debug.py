import json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
qa=ROOT/'qa/whole_house'
r=json.loads((qa/'physics_rooms_results.json').read_text())
layout=json.loads((qa/'layout_bounds.json').read_text())
keys=['terreo_Cozinha_Richard','terreo_Biblioteca','primeiro_Suite_Casal','primeiro_Closet_Casal','primeiro_Closet_Infantil','primeiro_Hall_Superior']
fig,axes=plt.subplots(2,3,figsize=(18,11),constrained_layout=True)
for ax,key in zip(axes.flat,keys):
    d=next(d for d in r['rooms'] if d['room']==key)
    grid=np.array(d['grid_mask']); x,z=d['grid_origin'];step=d['grid_spacing']
    ax.imshow(grid,origin='lower',extent=(x-step/2,x+(grid.shape[1]-.5)*step,z-step/2,z+(grid.shape[0]-.5)*step),cmap=ListedColormap(['#263342','#f29a38','#8ac5b0']),vmin=0,vmax=2,interpolation='nearest')
    ax.scatter(*zip(*d['exit_world_xz']),c='red',marker='x',s=45)
    floor='Terreo' if key.startswith('terreo_') else 'Primeiro_Andar'
    roomname=key.split('_',1)[1]
    for p in layout.get(floor+'/'+roomname,[]):
        px,py,pz=p['position']
        ax.text(px,pz,p['name'].replace('Modelo_','').replace('CompletaBiblioteca','Estante')[:24],fontsize=6,color='#142a4d',clip_on=True)
    ax.set(title=f"{key}\nConectado {d['connected_free_ratio']:.1%}",xlabel='X (m)',ylabel='Z (m)')
    ax.set_aspect('equal');ax.grid(alpha=.25)
fig.suptitle('Mapa real: escuro = bloqueado/sem piso; verde = acessível; laranja = livre mas isolado',fontsize=15)
fig.savefig(qa/'navigation_debug.png',dpi=130)
print(qa/'navigation_debug.png')

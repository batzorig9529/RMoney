import * as THREE from 'three';

const notify = (message) => window.Scene?.postMessage(message);
try {
  const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true, preserveDrawingBuffer: true });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  renderer.setClearColor(0x000000, 0);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.1;
  document.body.appendChild(renderer.domElement);
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(34, 1, 0.1, 40);
  camera.position.set(0, 4.4, 5.9);
  camera.lookAt(0, 0, 0);
  scene.add(new THREE.HemisphereLight(0xffffff, 0x728682, 2));
  const key = new THREE.DirectionalLight(0xffffff, 3);
  key.position.set(-3, 7, 4);
  key.castShadow = true;
  key.shadow.mapSize.set(1024, 1024);
  key.shadow.camera.left = key.shadow.camera.bottom = -4;
  key.shadow.camera.right = key.shadow.camera.top = 4;
  key.shadow.bias = -0.001;
  scene.add(key);
  const rim = new THREE.DirectionalLight(0xc1fff0, 2);
  rim.position.set(4, 2, -3);
  scene.add(rim);
  const group = new THREE.Group();
  scene.add(group);
  const segments = new THREE.Group();
  group.add(segments);
  const plane = new THREE.Mesh(new THREE.PlaneGeometry(30, 30), new THREE.ShadowMaterial({ opacity: 0.14 }));
  plane.rotation.x = -Math.PI / 2;
  plane.position.y = -0.34;
  plane.receiveShadow = true;
  scene.add(plane);

  const label = document.createElement('canvas');
  label.width = label.height = 256;
  const ctx = label.getContext('2d');
  ctx.fillStyle = '#edf2f0';
  ctx.fillRect(0, 0, 256, 256);
  ctx.fillStyle = '#193d34';
  ctx.font = 'bold 150px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('\u20ae', 128, 140);
  const texture = new THREE.CanvasTexture(label);
  texture.colorSpace = THREE.SRGBColorSpace;
  const silver = new THREE.MeshStandardMaterial({ color: 0xcbd8d3, metalness: 0.55, roughness: 0.3 });
  const coin = new THREE.Mesh(new THREE.CylinderGeometry(0.79, 0.79, 0.18, 64), [
    silver, new THREE.MeshStandardMaterial({ map: texture, metalness: 0.18, roughness: 0.4 }), silver,
  ]);
  coin.position.y = 0.13;
  coin.castShadow = true;
  group.add(coin);
  let paused = matchMedia('(prefers-reduced-motion: reduce)').matches;
  let active = true;
  let angle = 0;
  let drag = null;
  let selected = -1;
  const colors = [0xf17f71, 0x3987b8, 0xb8a2da, 0x28ad83];

  function update(values) {
    for (const item of [...segments.children]) {
      segments.remove(item);
      item.geometry.dispose();
      item.material.dispose();
    }
    const amounts = values.map(v => Number.isFinite(v) ? Math.max(0, v) : 0);
    const total = amounts.reduce((a, b) => a + b, 0);
    const slices = total > 0 ? amounts : [1];
    let start = 0;
    slices.forEach((amount, index) => {
      if (amount <= 0) return;
      const sweep = amount / (total || 1) * Math.PI * 2;
      const gap = Math.min(0.035, sweep * 0.12);
      const end = start + sweep - gap;
      const shape = new THREE.Shape();
      shape.absarc(0, 0, 2, start, end, false);
      shape.absarc(0, 0, 1.18, end, start, true);
      shape.closePath();
      const geometry = new THREE.ExtrudeGeometry(shape, {
        depth: 0.3, bevelEnabled: true, bevelThickness: 0.06,
        bevelSize: Math.min(0.045, sweep * 0.1), bevelSegments: 3, steps: 1, curveSegments: 64,
      });
      geometry.rotateX(-Math.PI / 2);
      const material = new THREE.MeshStandardMaterial({
        color: total ? colors[index] : 0xc9d4cf, roughness: 0.29, metalness: 0.24,
      });
      const mesh = new THREE.Mesh(geometry, material);
      mesh.castShadow = mesh.receiveShadow = true;
      mesh.userData.index = total ? index : -1;
      segments.add(mesh);
      start += sweep;
    });
  }
  window.setFinance = ({ values, reducedMotion, running = true }) => {
    update(values);
    paused = reducedMotion;
    active = running;
  };
  window.setSceneActive = (value) => { active = value; };
  window.setScenePaused = (value) => { paused = value; };
  window.resetScene = () => { angle = 0; selected = -1; };
  window.selectSegment = (index) => { selected = index; };
  renderer.domElement.addEventListener('pointerdown', event => {
    drag = { x: event.clientX, origin: event.clientX };
    renderer.domElement.setPointerCapture(event.pointerId);
  });
  renderer.domElement.addEventListener('pointermove', event => {
    if (!drag) return;
    angle += (event.clientX - drag.x) * 0.008;
    drag.x = event.clientX;
  });
  renderer.domElement.addEventListener('pointerup', event => {
    if (drag && Math.abs(event.clientX - drag.origin) < 8) {
      const bounds = renderer.domElement.getBoundingClientRect();
      const point = new THREE.Vector2((event.clientX - bounds.left) / bounds.width * 2 - 1,
        -(event.clientY - bounds.top) / bounds.height * 2 + 1);
      const ray = new THREE.Raycaster();
      ray.setFromCamera(point, camera);
      selected = ray.intersectObjects(segments.children)[0]?.object.userData.index ?? -1;
      notify(`selected:${selected}`);
    }
    drag = null;
  });
  renderer.domElement.addEventListener('pointercancel', () => { drag = null; });
  function resize() {
    const width = innerWidth, height = innerHeight;
    renderer.setSize(width, height);
    camera.aspect = width / height;
    camera.position.set(0, 4.4, 5.9).multiplyScalar(Math.max(1, 1.1 / camera.aspect));
    camera.updateProjectionMatrix();
  }
  addEventListener('resize', resize);
  document.addEventListener('visibilitychange', () => { active = !document.hidden; });
  renderer.domElement.addEventListener('webglcontextlost', event => { event.preventDefault(); notify('error'); });
  update([0, 0, 0, 0]);
  resize();
  let last = 0;
  renderer.setAnimationLoop(time => {
    const delta = Math.min((time - last) / 1000, 0.05);
    last = time;
    if (!active) return;
    if (!paused && !drag) angle += delta * 0.1;
    group.rotation.y = angle;
    segments.children.forEach(mesh => {
      const target = mesh.userData.index === selected && selected >= 0 ? 0.22 : 0;
      mesh.position.y += (target - mesh.position.y) * 0.15;
    });
    renderer.render(scene, camera);
  });
  renderer.render(scene, camera);
  notify('ready');
} catch (error) {
  notify('error');
  console.error(error);
}

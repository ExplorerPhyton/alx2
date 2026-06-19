import * as THREE from 'three';
// Scene setup
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setClearColor(0x000000);
document.body.appendChild(renderer.domElement);
camera.position.z = 15;
// Lighting
const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
scene.add(ambientLight);
const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
directionalLight.position.set(5, 5, 5);
scene.add(directionalLight);
// Sphere data
const sphereData = [
    { position: [-6, 0, 0], color: 0xff6b6b, text: 'Location 1: Ancient Temple' },
    { position: [0, 0, 0], color: 0x4ecdc4, text: 'Location 2: Hidden Cave' },
    { position: [6, 0, 0], color: 0xffe66d, text: 'Location 3: Sacred Peak' }
];
const spheres = [];
let selectedSphere = null;
let initialCameraPos = { x: camera.position.x, y: camera.position.y, z: camera.position.z };
let textLabel = null;
let isAnimating = false;
let animationProgress = 0;
// Create spheres
sphereData.forEach((data, index) => {
    const geometry = new THREE.SphereGeometry(1, 32, 32);
    const material = new THREE.MeshPhongMaterial({ color: data.color });
    const sphere = new THREE.Mesh(geometry, material);
    sphere.position.set(data.position[0], data.position[1], data.position[2]);
    sphere.labelText = data.text; // Attach text to sphere
    sphere.sphereIndex = index; // Store index
    scene.add(sphere);
    spheres.push(sphere);
});
// Raycaster for click detection
const raycaster = new THREE.Raycaster();
const mouse = new THREE.Vector2();
// Create text label
function createTextLabel(text) {
    if (textLabel)
        textLabel.remove();
    textLabel = document.createElement('div');
    textLabel.textContent = text;
    textLabel.style.position = 'fixed';
    textLabel.style.bottom = '50px';
    textLabel.style.left = '50px';
    textLabel.style.color = '#ffffff';
    textLabel.style.fontSize = '24px';
    textLabel.style.fontFamily = 'Arial, sans-serif';
    textLabel.style.backgroundColor = 'rgba(0, 0, 0, 0.7)';
    textLabel.style.padding = '20px';
    textLabel.style.borderRadius = '10px';
    textLabel.style.maxWidth = '400px';
    textLabel.style.animation = 'fadeIn 0.3s ease-in';
    document.body.appendChild(textLabel);
}
// Mouse click handler
window.addEventListener('click', (event) => {
    if (isAnimating)
        return; // Prevent multiple clicks during animation
    mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
    raycaster.setFromCamera(mouse, camera);
    const intersects = raycaster.intersectObjects(spheres);
    if (intersects.length > 0) {
        const clickedSphere = intersects[0].object;
        selectedSphere = clickedSphere;
        // Start animation to zoom into this sphere
        isAnimating = true;
        animationProgress = 0;
        createTextLabel(selectedSphere.labelText);
    }
    else {
        if (selectedSphere) {
            // Reset zoom
            isAnimating = true;
            animationProgress = 0;
            selectedSphere = null;
            if (textLabel)
                textLabel.remove();
        }
    }
});
// Add CSS animation
const style = document.createElement('style');
style.textContent = `
  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translateY(10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  body {
    margin: 0;
    overflow: hidden;
    background-color: #000;
  }
`;
document.head.appendChild(style);
// Animation loop
function animate() {
    requestAnimationFrame(animate);
    // Rotate spheres
    spheres.forEach(sphere => {
        sphere.rotation.x += 0.003;
        sphere.rotation.y += 0.005;
    });
    // Handle camera zoom animation
    if (isAnimating) {
        animationProgress += 0.05; // Speed of animation
        if (animationProgress >= 1) {
            animationProgress = 1;
            isAnimating = false;
        }
        const easeProgress = animationProgress < 0.5
            ? 2 * animationProgress * animationProgress
            : -1 + (4 - 2 * animationProgress) * animationProgress; // Ease in-out
        if (selectedSphere) {
            // Zoom to selected sphere
            const targetX = selectedSphere.position.x;
            const targetY = selectedSphere.position.y;
            const targetZ = selectedSphere.position.z + 3; // Distance from sphere
            camera.position.x = initialCameraPos.x + (targetX - initialCameraPos.x) * easeProgress;
            camera.position.y = initialCameraPos.y + (targetY - initialCameraPos.y) * easeProgress;
            camera.position.z = initialCameraPos.z + (targetZ - initialCameraPos.z) * easeProgress;
            camera.lookAt(selectedSphere.position);
        }
        else {
            // Zoom back out
            camera.position.x = initialCameraPos.x + (camera.position.x - initialCameraPos.x) * (1 - easeProgress);
            camera.position.y = initialCameraPos.y + (camera.position.y - initialCameraPos.y) * (1 - easeProgress);
            camera.position.z = initialCameraPos.z + (camera.position.z - initialCameraPos.z) * (1 - easeProgress);
            camera.lookAt(0, 0, 0);
        }
    }
    renderer.render(scene, camera);
}
// Handle window resize
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
});
animate();
//# sourceMappingURL=main.js.map
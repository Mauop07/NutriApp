// Importaciones modulares de Firebase v10
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.5.0/firebase-app.js";
import { getFirestore, collection, getDocs, doc, setDoc, deleteDoc } from "https://www.gstatic.com/firebasejs/10.5.0/firebase-firestore.js";
import { getAuth, onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/10.5.0/firebase-auth.js";

const firebaseConfig = {
    apiKey: "AIzaSyDyrMofbBJwepKxQKU6MC42HNWDwNaPCW8",
    authDomain: "nutriapp-grupo6.firebaseapp.com",
    projectId: "nutriapp-grupo6",
    storageBucket: "nutriapp-grupo6.firebasestorage.app",
    messagingSenderId: "190206968334",
    appId: "1:190206968334:web:c32281725602697beab25f"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

// Estado global
let alimentosGlobales = [];
const modalApp = new bootstrap.Modal(document.getElementById('modalAlimento'));

// ---------------------------------------------------------
// 1. CARGA Y LECTURA (SCRUM-35)
// ---------------------------------------------------------
async function cargarAlimentos() {
    const tabla = document.getElementById('tabla-alimentos');
    try {
        const querySnapshot = await getDocs(collection(db, "catalogo_alimentos"));
        alimentosGlobales = [];
        
        querySnapshot.forEach((doc) => {
            const data = doc.data();
            if(data.categoria !== 'Personalizado') {
                alimentosGlobales.push({ id: doc.id, ...data });
            }
        });
        
        renderizarTabla(alimentosGlobales);
    } catch (error) {
        console.error("Error leyendo Firebase:", error);
        tabla.innerHTML = `<tr><td colspan="3" class="text-danger text-center">Error al conectar con la base de datos.</td></tr>`;
    }
}

function renderizarTabla(alimentos) {
    const tabla = document.getElementById('tabla-alimentos');
    tabla.innerHTML = '';

    if (alimentos.length === 0) {
        tabla.innerHTML = `<tr><td colspan="3" class="text-center text-muted py-4">No se encontraron alimentos.</td></tr>`;
        return;
    }

    alimentos.forEach(alimento => {
        const unidadesHtml = (alimento.unidades || []).map(u => `
            <div class="unidad-fila d-flex justify-content-between mb-1" style="max-width: 250px;">
                <span>${u.unidad}</span>
                <span class="text-muted">${u.kcal} kcal</span>
            </div>
        `).join('');

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td class="ps-4 fw-bold text-dark text-nowrap">${alimento.nombre}</td>
            <td class="py-3">${unidadesHtml}</td>
            <td class="text-center pe-4 text-nowrap">
                <button class="btn btn-sm btn-primary rounded-3 px-3 me-2 fw-bold" onclick="abrirEdicion('${alimento.id}')">Editar</button>
                <button class="btn btn-sm btn-outline-danger rounded-3 px-3 fw-bold" onclick="eliminarAlimento('${alimento.id}')">Eliminar</button>
            </td>
        `;
        tabla.appendChild(tr);
    });
}

// Búsqueda en tiempo real
document.getElementById('buscador').addEventListener('input', (e) => {
    const texto = e.target.value.toLowerCase();
    const filtrados = alimentosGlobales.filter(a => a.nombre.toLowerCase().includes(texto));
    renderizarTabla(filtrados);
});

// ---------------------------------------------------------
// 2. CREAR Y EDITAR 
// ---------------------------------------------------------
window.abrirModal = () => {
    document.getElementById('formAlimento').reset();
    document.getElementById('alimentoId').value = '';
    document.getElementById('modalTitulo').innerText = 'Nuevo Alimento';
    document.getElementById('contenedorUnidades').innerHTML = '';
    agregarFilaUnidad(); 
    modalApp.show();
};

window.abrirEdicion = (id) => {
    const alimento = alimentosGlobales.find(a => a.id === id);
    if (!alimento) return;

    document.getElementById('alimentoId').value = alimento.id;
    document.getElementById('alimentoNombre').value = alimento.nombre;
    document.getElementById('modalTitulo').innerText = 'Editar Alimento';
    
    document.getElementById('contenedorUnidades').innerHTML = '';
    if (alimento.unidades && alimento.unidades.length > 0) {
        alimento.unidades.forEach(u => agregarFilaUnidad(u.unidad, u.kcal));
    } else {
        agregarFilaUnidad();
    }
    
    modalApp.show();
};

// Dinámica del formulario de unidades
window.agregarFilaUnidad = (unidadVal = '', kcalVal = '') => {
    const div = document.createElement('div');
    div.className = 'd-flex gap-2 mb-2 fila-unidad';
    div.innerHTML = `
        <input type="text" class="form-control bg-light border-0 val-unidad" placeholder="Ej. 1 taza" value="${unidadVal}" required>
        <input type="number" class="form-control bg-light border-0 val-kcal" placeholder="Kcal" value="${kcalVal}" required style="width: 100px;">
        <button type="button" class="btn btn-light text-danger border-0" onclick="this.parentElement.remove()"><i class="bi bi-trash"></i></button>
    `;
    document.getElementById('contenedorUnidades').appendChild(div);
};

// Guardar en Firestore
document.getElementById('formAlimento').addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('alimentoId').value;
    const nombre = document.getElementById('alimentoNombre').value.trim();
    const btnGuardar = document.getElementById('btnGuardar');
    
    // Recopilar unidades
    const unidades = [];
    document.querySelectorAll('.fila-unidad').forEach(fila => {
        const unidad = fila.querySelector('.val-unidad').value.trim();
        const kcal = parseInt(fila.querySelector('.val-kcal').value);
        if(unidad && !isNaN(kcal)) unidades.push({ unidad, kcal });
    });

    if (unidades.length === 0) {
        alert("Agrega al menos una unidad válida.");
        return;
    }

    btnGuardar.disabled = true;
    btnGuardar.innerText = 'Guardando...';

    // Lógica de ID 
    const docId = id || nombre.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');

    const data = {
        nombre: nombre,
        unidades: unidades,
        categoria: 'General' 
    };

    try {
        await setDoc(doc(db, "catalogo_alimentos", docId), data);
        modalApp.hide();
        cargarAlimentos();
    } catch (error) {
        console.error("Error guardando:", error);
        alert("Hubo un error al guardar el alimento.");
    } finally {
        btnGuardar.disabled = false;
        btnGuardar.innerText = 'Guardar en Catálogo';
    }
});

// ---------------------------------------------------------
// 3. ELIMINAR 
// ---------------------------------------------------------
window.eliminarAlimento = async (id) => {
    if (confirm("¿Estás seguro de eliminar permanentemente este alimento de la base general?")) {
        try {
            await deleteDoc(doc(db, "catalogo_alimentos", id));
            cargarAlimentos();
        } catch (error) {
            console.error("Error eliminando:", error);
            alert("No se pudo eliminar el alimento.");
        }
    }
};

onAuthStateChanged(auth, (user) => {
    if (user && user.email === 'admin_nutriapp@gmail.com') {
        document.getElementById('cuerpoApp').style.opacity = '1'; 
        cargarAlimentos();
    } else {
        if (user) signOut(auth);
        window.location.replace("login.html");
    }
});

// ---------------------------------------------------------
// 4. CERRAR SESIÓN
// ---------------------------------------------------------
document.getElementById('btnCerrarSesion').addEventListener('click', () => {
    signOut(auth).then(() => {
        window.location.replace("login.html");
    });
});
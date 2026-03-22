
const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'cbk_devmenu'
const app = document.getElementById('app')
const title = document.getElementById('title')
const vehicleModelInput = document.getElementById('vehicleModel')
const toast = document.getElementById('toast')

const state = {}

const post = async (endpoint, payload = {}) => {
    await fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
    })
}

const setButtonStates = (data) => {
    Object.assign(state, data || {})
    document.querySelectorAll('[data-toggle]').forEach((button) => {
        const key = button.dataset.toggle
        button.classList.toggle('active', !!state[key])
    })
}

const setStatus = (data) => {
    if (!data) return
    setButtonStates(data)
    document.getElementById('area').textContent = data.area || '-'
    document.getElementById('coordX').textContent = data.coords?.x?.toFixed?.(2) ?? '0.00'
    document.getElementById('coordY').textContent = data.coords?.y?.toFixed?.(2) ?? '0.00'
    document.getElementById('coordZ').textContent = data.coords?.z?.toFixed?.(2) ?? '0.00'
    document.getElementById('coordH').textContent = data.coords?.h?.toFixed?.(2) ?? '0.00'
    document.getElementById('vehicleName').textContent = data.inVehicle ? (data.vehicleName || 'UNKNOWN') : 'None'
}

const showToast = (message) => {
    toast.textContent = message
    toast.style.display = 'block'
    clearTimeout(showToast.timer)
    showToast.timer = setTimeout(() => {
        toast.style.display = 'none'
    }, 2200)
}

document.getElementById('closeBtn').addEventListener('click', () => post('close'))

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        post('close')
    }
})

document.querySelectorAll('[data-toggle]').forEach((button) => {
    button.addEventListener('click', async () => {
        await post('toggle', { key: button.dataset.toggle })
    })
})

document.querySelectorAll('[data-action]').forEach((button) => {
    button.addEventListener('click', async () => {
        const action = button.dataset.action
        const payload = { name: action }
        if (action === 'spawn_vehicle') {
            payload.value = vehicleModelInput.value.trim()
        }
        await post('action', payload)
    })
})

vehicleModelInput.addEventListener('keydown', async (event) => {
    if (event.key === 'Enter') {
        await post('action', { name: 'spawn_vehicle', value: vehicleModelInput.value.trim() })
    }
})

window.addEventListener('message', async (event) => {
    const { action, data, title: menuTitle, text } = event.data || {}

    if (action === 'open') {
        app.classList.remove('hidden')
        title.textContent = menuTitle || 'CBK Dev Menu'
        const resp = await fetch(`https://${resourceName}/getStatus`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: '{}'
        })
        const status = await resp.json()
        setStatus(status)
    } else if (action === 'close') {
        app.classList.add('hidden')
    } else if (action === 'setState') {
        setButtonStates(data)
    } else if (action === 'status') {
        setStatus(data)
    } else if (action === 'copyCoords') {
        try {
            await navigator.clipboard.writeText(text)
            showToast(`Copied: ${text}`)
        } catch (err) {
            showToast(text)
        }
    }
})

const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'cbk_devmenu'
const app = document.getElementById('app')
const title = document.getElementById('title')
const vehicleModelInput = document.getElementById('vehicleModel')
const timeHourInput = document.getElementById('timeHour')
const timeMinuteInput = document.getElementById('timeMinute')
const toast = document.getElementById('toast')

const state = {}

const post = async (endpoint, payload = {}) => {
    const response = await fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
    })
    return response.json().catch(() => ({}))
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
    document.getElementById('weatherName').textContent = data.currentWeather || 'CLEAR'
    document.getElementById('clockTime').textContent = `${String(data.timeHour ?? 12).padStart(2, '0')}:${String(data.timeMinute ?? 0).padStart(2, '0')}`
    document.getElementById('coordX').textContent = data.coords?.x?.toFixed?.(2) ?? '0.00'
    document.getElementById('coordY').textContent = data.coords?.y?.toFixed?.(2) ?? '0.00'
    document.getElementById('coordZ').textContent = data.coords?.z?.toFixed?.(2) ?? '0.00'
    document.getElementById('coordH').textContent = data.coords?.h?.toFixed?.(2) ?? '0.00'
    document.getElementById('vehicleName').textContent = data.inVehicle ? (data.vehicleName || 'UNKNOWN') : 'None'

    if (document.activeElement !== timeHourInput) {
        timeHourInput.value = data.timeHour ?? 12
    }
    if (document.activeElement !== timeMinuteInput) {
        timeMinuteInput.value = data.timeMinute ?? 0
    }
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
        const result = await post('toggle', { key: button.dataset.toggle })
        if (result?.state) setStatus(result.state)
    })
})

document.querySelectorAll('[data-action]').forEach((button) => {
    button.addEventListener('click', async () => {
        const action = button.dataset.action
        const payload = { name: action }

        if (action === 'spawn_vehicle') {
            payload.value = vehicleModelInput.value.trim()
        } else if (action === 'set_weather') {
            payload.name = 'set_weather'
            payload.value = button.dataset.value
        } else if (action === 'set_time_preset') {
            payload.name = 'set_time'
            payload.hour = Number(button.dataset.hour)
            payload.minute = Number(button.dataset.minute)
        } else if (action === 'set_time_custom') {
            payload.name = 'set_time'
            payload.hour = Number(timeHourInput.value)
            payload.minute = Number(timeMinuteInput.value)
        }

        const result = await post('action', payload)
        if (result?.state) setStatus(result.state)
    })
})

vehicleModelInput.addEventListener('keydown', async (event) => {
    if (event.key === 'Enter') {
        const result = await post('action', { name: 'spawn_vehicle', value: vehicleModelInput.value.trim() })
        if (result?.state) setStatus(result.state)
    }
})

window.addEventListener('message', async (event) => {
    const { action, data, title: menuTitle, text } = event.data || {}

    if (action === 'open') {
        app.classList.remove('hidden')
        title.textContent = menuTitle || 'CBK Dev Menu'
        const status = await post('getStatus')
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
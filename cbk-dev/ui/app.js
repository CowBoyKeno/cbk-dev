const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'cbk_devmenu'
const app = document.getElementById('app')
const title = document.getElementById('title')
const vehicleModelInput = document.getElementById('vehicleModel')
const timeHourInput = document.getElementById('timeHour')
const timeMinuteInput = document.getElementById('timeMinute')
const toast = document.getElementById('toast')
const vehicleModsContainer = document.getElementById('vehicleMods')
const vehicleExtrasContainer = document.getElementById('vehicleExtras')
const windowTintSelect = document.getElementById('windowTintSelect')
const liverySelect = document.getElementById('liverySelect')
const plateIndexSelect = document.getElementById('plateIndexSelect')
const vehicleNeonContainer = document.getElementById('vehicleNeon')
const neonColorR = document.getElementById('neonColorR')
const neonColorG = document.getElementById('neonColorG')
const neonColorB = document.getElementById('neonColorB')
const sectionButtons = document.querySelectorAll('[data-page-btn]')
const resizeHandle = document.getElementById('resizeHandle')

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

const setPage = (pageName) => {
    document.querySelectorAll('.page').forEach((page) => {
        page.classList.toggle('hidden', page.dataset.page !== pageName)
    })
    sectionButtons.forEach((button) => {
        button.classList.toggle('active', button.dataset.pageBtn === pageName)
    })
}

sectionButtons.forEach((button) => {
    button.addEventListener('click', () => {
        setPage(button.dataset.pageBtn)
    })
})

let isResizing = false
let resizeStart = { x: 0, y: 0 }
let startSize = { width: 0, height: 0 }

const startResize = (event) => {
    isResizing = true
    resizeStart.x = event.clientX
    resizeStart.y = event.clientY
    const rect = app.getBoundingClientRect()
    startSize.width = rect.width
    startSize.height = rect.height
    event.preventDefault()
}

const handleResize = (event) => {
    if (!isResizing) return
    const dx = event.clientX - resizeStart.x
    const dy = event.clientY - resizeStart.y
    const newWidth = Math.max(520, startSize.width + dx)
    const newHeight = Math.max(420, startSize.height + dy)
    app.style.width = `${newWidth}px`
    app.style.height = `${newHeight}px`
}

const stopResize = () => {
    isResizing = false
}

resizeHandle.addEventListener('mousedown', startResize)
document.addEventListener('mousemove', handleResize)
document.addEventListener('mouseup', stopResize)

const buildSelectOptions = (options, currentValue) => {
    return options
        .map((option) => `<option value="${option.value}" ${option.value === currentValue ? 'selected' : ''}>${option.label}</option>`)
        .join('')
}

const renderVehicleModifiers = (data) => {
    if (!data || !Array.isArray(data.mods)) {
        vehicleModsContainer.innerHTML = '<p>No vehicle data available.</p>'
        vehicleExtrasContainer.innerHTML = ''
        windowTintSelect.innerHTML = ''
        liverySelect.innerHTML = ''
        plateIndexSelect.innerHTML = ''
        vehicleNeonContainer.innerHTML = ''
        return
    }

    vehicleModsContainer.innerHTML = data.mods
        .map((mod) => {
            return `
                <div class="mod-row">
                    <label for="vehicleMod_${mod.type}">${mod.name}</label>
                    <select id="vehicleMod_${mod.type}" data-action="set_vehicle_mod" data-modtype="${mod.type}">
                        ${buildSelectOptions(mod.options, mod.current)}
                    </select>
                </div>`
        })
        .join('')

    vehicleExtrasContainer.innerHTML = data.extras.length > 0
        ? data.extras.map((extra) => `
              <button data-action="toggle_vehicle_extra" data-extra-index="${extra.index}" data-enabled="${extra.enabled}" class="toggle">${extra.enabled ? 'Disable' : 'Enable'} ${extra.name}</button>
          `).join('')
        : '<p>No vehicle extras available.</p>'

    windowTintSelect.innerHTML = data.windowTintOptions
        ? buildSelectOptions(Object.entries(data.windowTintOptions).map(([value, label]) => ({ value: Number(value), label })), data.windowTint)
        : ''

    liverySelect.innerHTML = data.livery
        ? buildSelectOptions(data.livery.options, data.livery.current)
        : '<option value="">No livery available</option>'

    plateIndexSelect.innerHTML = data.plateIndexOptions
        ? buildSelectOptions(Object.entries(data.plateIndexOptions).map(([value, label]) => ({ value: Number(value), label })), data.plateIndex)
        : ''

    vehicleNeonContainer.innerHTML = ['left', 'right', 'front', 'back']
        .map((section, index) => `
            <button data-action="toggle_neon" data-neon-slot="${index}" data-enabled="${data.neon[section]}" class="toggle">
                ${data.neon[section] ? 'Disable' : 'Enable'} Neon ${section}
            </button>
        `).join('')

    if (neonColorR && neonColorG && neonColorB) {
        neonColorR.value = data.neonColor?.r ?? 0
        neonColorG.value = data.neonColor?.g ?? 0
        neonColorB.value = data.neonColor?.b ?? 0
    }
}

const refreshVehicleData = async () => {
    const result = await post('getVehicleMods')
    if (result?.ok && result.data) {
        renderVehicleModifiers(result.data)
    } else {
        vehicleModsContainer.innerHTML = '<p>Enter a vehicle and sit in the driver seat to use mods.</p>'
        vehicleExtrasContainer.innerHTML = ''
        windowTintSelect.innerHTML = ''
        liverySelect.innerHTML = ''
        plateIndexSelect.innerHTML = ''
        vehicleNeonContainer.innerHTML = ''
    }
}

const handleAction = async (payload) => {
    const result = await post('action', payload)
    if (result?.state) setStatus(result.state)
    if ([
        'set_vehicle_mod',
        'toggle_vehicle_extra',
        'set_window_tint',
        'set_livery',
        'set_plate_index',
        'toggle_neon',
        'set_neon_color'
    ].includes(payload.name)) {
        await refreshVehicleData()
    }
}

document.getElementById('closeBtn').addEventListener('click', () => post('close'))

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        post('close')
    }
})

document.body.addEventListener('click', async (event) => {
    const button = event.target.closest('[data-action]')
    if (!button) return

    const action = button.dataset.action
    if (action === 'toggle_vehicle_extra') {
        const extraIndex = Number(button.dataset.extraIndex)
        const enabled = button.dataset.enabled === 'true'
        await handleAction({ name: action, extraIndex, enabled: !enabled })
        return
    }

    if (action === 'toggle_neon') {
        const slot = Number(button.dataset.neonSlot)
        const enabled = button.dataset.enabled === 'true'
        await handleAction({ name: action, neonSlot: slot, enabled: !enabled })
        return
    }

    if (action === 'refresh_vehicle_data') {
        await refreshVehicleData()
        return
    }

    if (['heal', 'tp_waypoint', 'spawn_vehicle', 'repair_vehicle', 'clean_vehicle', 'flip_vehicle', 'delete_vehicle', 'max_vehicle', 'engine_toggle', 'give_weapons', 'refill_ammo', 'remove_weapons'].includes(action)) {
        const payload = { name: action }
        if (action === 'spawn_vehicle') {
            payload.value = vehicleModelInput.value.trim()
        }
        await handleAction(payload)
        return
    }

    if (action === 'set_weather' || action === 'set_time_custom' || action === 'copy_coords') {
        const payload = { name: action }
        if (action === 'set_weather') {
            payload.value = button.dataset.value
        } else if (action === 'set_time_custom') {
            payload.hour = Number(timeHourInput.value)
            payload.minute = Number(timeMinuteInput.value)
        }
        await handleAction(payload)
    }
})

window.addEventListener('load', () => {
    setPage('player')
})

document.body.addEventListener('change', async (event) => {
    const control = event.target.closest('[data-action]')
    if (!control) return

    const action = control.dataset.action
    if (action === 'set_vehicle_mod') {
        await handleAction({
            name: action,
            modType: Number(control.dataset.modtype),
            modIndex: Number(control.value)
        })
    }

    if (action === 'set_window_tint') {
        await handleAction({
            name: action,
            tintIndex: Number(control.value)
        })
    }

    if (action === 'set_livery') {
        await handleAction({
            name: action,
            liveryIndex: Number(control.value)
        })
    }

    if (action === 'set_plate_index') {
        await handleAction({
            name: action,
            plateIndex: Number(control.value)
        })
    }
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
        await refreshVehicleData()
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

let isDragging = false
let dragOffset = { x: 0, y: 0 }

const getHeaderElement = () => document.querySelector('.header')

const clamp = (value, min, max) => Math.min(Math.max(value, min), max)

const updateAppPosition = (left, top) => {
    const rect = app.getBoundingClientRect()
    const maxLeft = window.innerWidth - rect.width
    const maxTop = window.innerHeight - rect.height
    app.style.left = `${clamp(left, 0, Math.max(0, maxLeft))}px`
    app.style.top = `${clamp(top, 0, Math.max(0, maxTop))}px`
}

const handlePointerMove = (event) => {
    if (!isDragging) return
    updateAppPosition(event.clientX - dragOffset.x, event.clientY - dragOffset.y)
}

const stopDragging = () => {
    isDragging = false
}

const startDragging = (event) => {
    const header = getHeaderElement()
    if (!header || event.target.closest('button') || event.target.closest('input') || event.target.closest('select')) {
        return
    }
    isDragging = true
    const rect = app.getBoundingClientRect()
    dragOffset.x = event.clientX - rect.left
    dragOffset.y = event.clientY - rect.top
}

document.addEventListener('mousemove', handlePointerMove)
document.addEventListener('mouseup', stopDragging)

document.addEventListener('mousedown', (event) => {
    const header = getHeaderElement()
    if (header && header.contains(event.target)) {
        startDragging(event)
    }
})

window.addEventListener('resize', () => {
    const rect = app.getBoundingClientRect()
    updateAppPosition(rect.left, rect.top)
})
;(() => {
    setTimeout(() => {
    const quickVehicles = [
        ['Adder', 'adder'],
        ['Sultan RS', 'sultanrs'],
        ['Kuruma', 'kuruma'],
        ['Zentorno', 'zentorno'],
        ['T20', 't20'],
        ['Elegy RH8', 'elegy2'],
        ['Bati 801', 'bati'],
        ['Sanchez', 'sanchez'],
        ['BF400', 'bf400'],
        ['Sandking XL', 'sandking'],
        ['Police Cruiser', 'police'],
        ['Police Buffalo', 'police2'],
        ['Sheriff SUV', 'sheriff2'],
        ['Ambulance', 'ambulance'],
        ['Fire Truck', 'firetruk'],
        ['Buzzard', 'buzzard2'],
        ['Maverick', 'maverick'],
        ['Frogger', 'frogger'],
        ['Akula', 'akula'],
        ['Flatbed', 'flatbed'],
        ['Tow Truck', 'towtruck'],
        ['Mule', 'mule'],
        ['Bus', 'bus'],
        ['Dinghy', 'dinghy'],
        ['Seashark', 'seashark']
    ]

    const enhancementResourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'cbk_devmenu'
    const uiState = {}
    const getVehicleInput = () => document.getElementById('vehicleModel')
    const getApp = () => document.getElementById('app')
    const postNui = async (endpoint, payload = {}) => {
        try {
            const response = await fetch(`https://${enhancementResourceName}/${endpoint}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(payload)
            })
            return response.json().catch(() => ({}))
        } catch (error) {
            return {}
        }
    }

    const normalize = (value) => String(value || '').trim().toLowerCase()

    const baseToggleLabel = (button) => {
        if (!button.dataset.baseLabel) {
            button.dataset.baseLabel = button.textContent.trim().replace(/^(enable|disable)\s+/i, '')
        }
        return button.dataset.baseLabel
    }

    const setToggleVisual = (button, enabled) => {
        const label = baseToggleLabel(button)
        button.classList.toggle('active', enabled)
        button.setAttribute('aria-pressed', String(enabled))
        button.textContent = `${enabled ? 'Disable' : 'Enable'} ${label}`
    }

    const syncToggleVisuals = () => {
        document.querySelectorAll('[data-toggle]').forEach((button) => {
            const key = button.dataset.toggle
            const enabled = key in uiState ? !!uiState[key] : button.classList.contains('active')
            setToggleVisual(button, enabled)
        })
    }

    const setSelected = (button, selected) => {
        button.classList.toggle('selected', selected)
        button.setAttribute('aria-pressed', String(selected))
    }

    const syncChoiceVisuals = () => {
        const currentWeather = normalize(uiState.currentWeather)
        document.querySelectorAll('[data-action="set_weather"][data-value]').forEach((button) => {
            setSelected(button, normalize(button.dataset.value) === currentWeather)
        })

        const currentHour = Number(uiState.timeHour)
        const currentMinute = Number(uiState.timeMinute)
        document.querySelectorAll('[data-action="set_time_preset"]').forEach((button) => {
            setSelected(button, Number(button.dataset.hour) === currentHour && Number(button.dataset.minute) === currentMinute)
        })

        const currentVehicle = normalize(getVehicleInput()?.value)
        document.querySelectorAll('[data-quick-vehicle]').forEach((button) => {
            setSelected(button, normalize(button.dataset.value) === currentVehicle)
        })
    }

    const markPressed = (button) => {
        button.classList.add('pressed')
        clearTimeout(button._pressedTimer)
        button._pressedTimer = setTimeout(() => button.classList.remove('pressed'), 260)
    }

    const clampTime = (value, min, max) => {
        const number = Number(value)
        if (!Number.isFinite(number)) return null
        return Math.max(min, Math.min(max, Math.floor(number)))
    }

    const updateDisplayedTime = (hour, minute) => {
        uiState.timeHour = hour
        uiState.timeMinute = minute

        const hourInput = document.getElementById('timeHour')
        const minuteInput = document.getElementById('timeMinute')
        if (hourInput && document.activeElement !== hourInput) {
            hourInput.value = hour
        }
        if (minuteInput && document.activeElement !== minuteInput) {
            minuteInput.value = minute
        }

        const clock = document.getElementById('clockTime')
        if (clock) {
            clock.textContent = `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`
        }

        syncChoiceVisuals()
    }

    const handleTimeClick = async (button, event) => {
        event.preventDefault()
        event.stopImmediatePropagation()

        const action = button.dataset.action || ''
        const hourInput = document.getElementById('timeHour')
        const minuteInput = document.getElementById('timeMinute')
        const usesCustomInputs = action === 'set_time_custom' || !button.hasAttribute('data-hour') || !button.hasAttribute('data-minute')
        const rawHour = usesCustomInputs ? hourInput?.value : button.dataset.hour
        const rawMinute = usesCustomInputs ? minuteInput?.value : button.dataset.minute
        const hour = clampTime(rawHour, 0, 23)
        const minute = clampTime(rawMinute, 0, 59)

        if (hour === null || minute === null) {
            return
        }

        markPressed(button)
        updateDisplayedTime(hour, minute)

        const result = await postNui('action', { name: 'set_time', hour, minute })
        if (result?.state) {
            Object.assign(uiState, result.state)
            if (typeof setStatus === 'function') {
                setStatus(result.state)
            }
            updateDisplayedTime(uiState.timeHour ?? hour, uiState.timeMinute ?? minute)
        }
    }

    document.addEventListener('click', (event) => {
        const button = event.target.closest('button[data-action="set_time_preset"], button[data-action="set_time_custom"], button[data-action="set_time"], button[data-hour][data-minute]')
        if (button) {
            handleTimeClick(button, event)
        }
    }, true)

    const spawnVehicleOption = async (button) => {
        const model = normalize(button.dataset.value)
        if (!model) return
        const input = getVehicleInput()
        if (input) {
            input.value = model
        }
        syncChoiceVisuals()
        markPressed(button)

        const result = await postNui('action', { name: 'spawn_vehicle', value: model })
        if (result?.state) {
            Object.assign(uiState, result.state)
            if (typeof setStatus === 'function') {
                setStatus(result.state)
            }
        }
        syncToggleVisuals()
        syncChoiceVisuals()
    }

    const buildQuickVehicles = () => {
        const input = getVehicleInput()
        if (!input || document.querySelector('[data-quick-vehicle-panel]')) return

        const anchor = input.closest('.stack') || input.parentElement
        if (!anchor) return

        const wrapper = document.createElement('div')
        wrapper.className = 'stack quick-vehicle-panel'
        wrapper.dataset.quickVehiclePanel = 'true'

        const label = document.createElement('label')
        label.textContent = 'Quick spawn options'

        const row = document.createElement('div')
        row.className = 'action-row wrap compact vehicle-options'

        quickVehicles.forEach(([labelText, model]) => {
            const button = document.createElement('button')
            button.type = 'button'
            button.dataset.quickVehicle = 'true'
            button.dataset.value = model
            button.textContent = labelText
            button.addEventListener('click', () => spawnVehicleOption(button))
            row.appendChild(button)
        })

        wrapper.append(label, row)
        anchor.insertAdjacentElement('afterend', wrapper)
    }

    document.querySelectorAll('[data-toggle]').forEach((button) => {
        baseToggleLabel(button)
        button.addEventListener('click', () => {
            setToggleVisual(button, !button.classList.contains('active'))
            markPressed(button)
            setTimeout(() => {
                syncToggleVisuals()
                syncChoiceVisuals()
            }, 250)
        })
    })

    document.querySelectorAll('[data-action]').forEach((button) => {
        button.addEventListener('click', () => {
            markPressed(button)
            setTimeout(() => {
                syncToggleVisuals()
                syncChoiceVisuals()
            }, 250)
        })
    })

    getVehicleInput()?.addEventListener('input', syncChoiceVisuals)

    window.addEventListener('message', (event) => {
        const { action, data } = event.data || {}
        if ((action === 'setState' || action === 'status') && data) {
            Object.assign(uiState, data)
        }

        setTimeout(() => {
            buildQuickVehicles()
            syncToggleVisuals()
            syncChoiceVisuals()
        }, 0)
    })

    buildQuickVehicles()
    syncToggleVisuals()
    syncChoiceVisuals()

    setInterval(() => {
        if (!getApp()?.classList.contains('hidden')) {
            buildQuickVehicles()
            syncToggleVisuals()
            syncChoiceVisuals()
        }
    }, 1000)
    }, 0)
})()

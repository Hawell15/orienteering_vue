<template>
    <div class="modal fade" tabindex="-1" aria-hidden="true" ref="modalRef">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Coeficienți ECN</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form @submit.prevent>
                        <table class="table table-bordered table-hover table-striped">
                            <thead class="table-primary">
                                <tr>
                                    <th scope="col">Grupa</th>
                                    <th>Coeficient</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="group in groups" :key="group.id">
                                    <td>{{group.group_name}}</td>
                                    <td>
                                        <select v-model="group.clasa" class="form-select form-select-sm">
                                            <option v-for="c in classes" :key="c.id" :value="String(c.id)">
                                                {{ c.category_name }}
                                            </option>
                                        </select>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Închide</button>
                    <button type="button" class="btn btn-primary" @click="handleSave">Salvează</button>
                </div>
            </div>
        </div>
    </div>
</template>
<script setup>
import { ref } from 'vue'
import axios from '@/axios'

const props = defineProps({
    competitionId: [String, Number]
})

const emit = defineEmits(['save'])

const groups = ref([])
const classes  = ref([])
const modalRef = ref(null)
let modalInstance = null

async function loadGroups() {
    const res = await axios.get(`/groups.json?competition=${props.competitionId}&sorting[sort_by]=group_name&sorting[direction]=asc`)
    groups.value = res.data.map(g => ({ ...g, clasa: g.clasa || defaultClasa(g.group_name) }))
}

function defaultClasa(groupName) {
    const match = groupName?.match(/\d+/)
    if (!match) return "10"

    const n = parseInt(match[0], 10)
    if (n < 13) return "7"
    if (n === 14 || n > 36) return "5"
    if (n >= 13 && n <= 36) return "4"
    return "10"
}

async function getClasaData() {
    const res = await axios.get('/groups/filters.json')
    classes.value = res.data.clase
}

function show() {
    loadGroups()
    getClasaData()
    if (!modalInstance) {
        modalInstance = new bootstrap.Modal(modalRef.value)
    }
    modalInstance.show()
}

function hide() {
    modalInstance.hide()
}

async function handleSave() {
    const payload = groups.value.map(g => ({ id: g.id, clasa: g.clasa || 0 }))
    await axios.post(`/competitions/${props.competitionId}/update_group_clasa.json`, { groups: payload })
    emit('save')
    hide()
}

defineExpose({ show })
</script>

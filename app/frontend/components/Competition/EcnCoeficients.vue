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
                                    <td><input type="text" step="0.1" class="form-control" v-model="group.ecn_coeficient" /></td>
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

const groups = ref([])
const modalRef = ref(null)
let modalInstance = null

async function loadGroups() {
    const res = await axios.get(`/competitions/${props.competitionId}/ecn_coeficients.json`)
    groups.value = res.data
}

function show() {
    loadGroups()
    if (!modalInstance) {
        modalInstance = new bootstrap.Modal(modalRef.value)
    }
    modalInstance.show()
}

function hide() {
    modalInstance.hide()
}

async function handleSave() {
    const payload = groups.value.map(g => ({ id: g.id, ecn_coeficient: g.ecn_coeficient || 0 }))
    await axios.post(`/competitions/${props.competitionId}/group_ecn_coeficients.json`, { groups: payload })
    hide()
}

defineExpose({ show })
</script>

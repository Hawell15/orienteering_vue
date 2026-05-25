<template>
    <table class="forest-table">
        <thead>
            <tr>
                <th class="sortable" @click="orderTable('id')">ID</th>
                <th class="sortable" @click="orderTable('date')">Data</th>
                <th class="sortable" @click="orderTable('competition_name')">Nume</th>
                <th class="sortable" @click="orderTable('location')">Oraș</th>
                <th class="sortable" @click="orderTable('country')">Țara</th>
                <th class="sortable" @click="orderTable('distance_type')">Tipul distanței</th>
                <th class="sortable" @click="orderTable('wre_id')">WRE</th>
                <th class="sortable" @click="orderTable('ecn')">ECN</th>
                <th>Acțiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td><a :href="`/competitions/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`/competitions/${element.id}`">{{ element.date }}</a></td>
                <td><a :href="`/competitions/${element.id}`">{{ element.competition_name }}</a></td>
                <td>{{ element.location }}</td>
                <td>{{ element.country }}</td>
                <td>{{ element.distance_type }}</td>
                <td>
                    <span v-if="element.wre_id" class="cell-badge wre">#{{ element.wre_id }}</span>
                    <span v-else class="cell-no">—</span>
                </td>
                <td>
                    <span v-if="element.ecn" class="cell-badge ecn">Da</span>
                    <span v-else class="cell-no">Nu</span>
                </td>
                <td>
                    <div class="row-actions">
                        <a class="row-action-btn show" :href="`/competitions/${element.id}`">Arată</a>
                        <button class="row-action-btn edit" @click="editElement(element)">Editează</button>
                        <button class="row-action-btn delete" @click="deleteElement(element.id)">Șterge</button>
                    </div>
                </td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :competition="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
const props = defineProps({
    elements: Object
})

const emit = defineEmits(['order'])

const modalElement = ref({})
const modal = ref(null)

function deleteElement(id) {
    if (confirm('Esti sigur ca vrei sa stergi această competiție?')) {
        axios.delete(`/competitions/${id}`).then(() => {
            props.elements = props.elements.filter(competition => competition.id !== id)
        })
    }
}

function editElement(element) {
    modalElement.value = { ...element }
    modal.value.show()
}

function updateElement(elementData, done) {
    axios.patch(`/competitions/${elementData.id}.json`, { competition: elementData }).then(res => {
        const index = props.elements.findIndex(c => c.id === res.data.id)
        if (index !== -1) props.elements[index] = { ...props.elements[index], ...res.data }
        done()
    })
}

function orderTable(sortKey) {
    emit('order', sortKey)
}
</script>

<style scoped src="../shared/index.css"></style>
